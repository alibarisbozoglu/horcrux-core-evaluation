// HORCRUX (vlsi-lab/HORCRUX, CORE-V-XIF PQC coprocessor) as a RoCC accelerator.
//
// Encoding (HORCRUX instructions moved into the RoCC custom opcodes; the HORCRUX sub-opcodes are kept):
//   custom0, funct7 = F                   -> HORCRUX R-type  {F, rs2, rs1, 111, rd, 0111011}
//   custom1, funct7 = 1_000000 (SETRS3)    -> latch rs1 as third operand of the next R4 instruction (xs1, no xd)
//   custom1, funct7 = 0_0_f3[2:0]_f2[1:0]  -> HORCRUX R4-type {00000, f2, rs2, rs1, f3, rd, 1101011}, rs3 = latched
// HORCRUX decodes only opcode/funct3/funct7/funct2, so the register-index fields of the rebuilt word are left 0.
// HORCRUX is a 32-bit unit: operands are the low 32 bits of the BOOM registers and the 32-bit result is
// sign-extended (RV64 keeps 32-bit values sign-extended in registers).
// One instruction in flight: HORCRUX returns exactly one result pulse per instruction and has no result_ready,
// so the response is held here until the core takes it. BOOM expects a response whenever xd = 1 (also rd = x0).
package horcrux

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.{Config, Parameters}
import org.chipsalliance.diplomacy.lazymodule.LazyModule
import freechips.rocketchip.tile._

class HorcruxRoCCAdapter extends BlackBox with HasBlackBoxResource {
  val io = IO(new Bundle {
    val clock      = Input(Clock())
    val reset      = Input(Bool())
    val req_valid  = Input(Bool())
    val req_ready  = Output(Bool())
    val req_instr  = Input(UInt(32.W))
    val req_rs1    = Input(UInt(32.W))
    val req_rs2    = Input(UInt(32.W))
    val req_rs3    = Input(UInt(32.W))
    val resp_valid = Output(Bool())
    val resp_data  = Output(UInt(32.W))
  })
  addResource("/vsrc/horcrux_rocc.sv") // HORCRUX RTL + HorcruxRoCCAdapter.sv (methods/horcrux_boom/gen_rtl.sh)
}

class HorcruxRoCC(opcodes: OpcodeSet)(implicit p: Parameters) extends LazyRoCC(opcodes) {
  override lazy val module = new HorcruxRoCCModuleImp(this)
}

class HorcruxRoCCModuleImp(outer: HorcruxRoCC)(implicit p: Parameters) extends LazyRoCCModuleImp(outer) {
  val cmd  = io.cmd.bits
  val inst = cmd.inst
  val isR4     = inst.opcode === "b0101011".U          // custom1
  val isSetRs3 = isR4 && inst.funct(6)

  val hx = Module(new HorcruxRoCCAdapter)
  hx.io.clock := clock
  hx.io.reset := reset.asBool

  val sIdle :: sWait :: sResp :: Nil = Enum(3)
  val state = RegInit(sIdle)
  val rs3   = Reg(UInt(32.W))
  val rd    = Reg(UInt(5.W))
  val xd    = Reg(Bool())
  val data  = Reg(UInt(32.W))

  // issue straight from the command (HORCRUX accepts combinationally when idle)
  val rType  = Cat(inst.funct, 0.U(10.W), "b111".U(3.W), 0.U(5.W), "b0111011".U(7.W))
  val r4Type = Cat(0.U(5.W), inst.funct(1, 0), 0.U(10.W), inst.funct(4, 2), 0.U(5.W), "b1101011".U(7.W))
  hx.io.req_valid := io.cmd.valid && state === sIdle && !isSetRs3
  hx.io.req_instr := Mux(isR4, r4Type, rType)
  hx.io.req_rs1   := cmd.rs1(31, 0)
  hx.io.req_rs2   := cmd.rs2(31, 0)
  hx.io.req_rs3   := rs3

  io.cmd.ready := state === sIdle && (isSetRs3 || hx.io.req_ready)

  when (io.cmd.fire) {
    when (isSetRs3) {
      rs3 := cmd.rs1(31, 0)
    } .otherwise {
      rd    := inst.rd
      xd    := inst.xd
      state := sWait
    }
  }
  when (state === sWait && hx.io.resp_valid) {
    data  := hx.io.resp_data
    state := Mux(xd, sResp, sIdle)
  }
  io.resp.valid     := state === sResp
  io.resp.bits.rd   := rd
  io.resp.bits.data := Cat(Fill(32, data(31)), data)
  when (io.resp.fire) { state := sIdle }

  io.busy      := state =/= sIdle
  io.interrupt := false.B
  io.mem.req.valid := false.B
}

/** Adds HORCRUX to every tile's RoCC list (custom0 + custom1). */
class WithHorcruxRoCC extends Config((site, here, up) => {
  case BuildRoCC => up(BuildRoCC) ++ Seq((p: Parameters) =>
    LazyModule(new HorcruxRoCC(OpcodeSet.custom0 | OpcodeSet.custom1)(p)))
})
