// HorcruxRoCCAdapter: plain-port shell around the unchanged HORCRUX coprocessor (horcrux_top).
//
// horcrux_top speaks CORE-V-XIF (if_xif, X_NUM_RS = 3). This shell owns the interface instance, ties off the
// channels HORCRUX does not use (compressed, memory, commit) and exposes the two it does:
//   issue : req_valid / req_ready (combinational from the HORCRUX decoder), 32-bit instruction word in the
//           original HORCRUX encoding, three 32-bit source operands
//   result: resp_valid is a one-cycle pulse (HORCRUX has no result_ready), resp_data = 32-bit result
// Every HORCRUX instruction returns exactly one result pulse, 1 to ~30 cycles after issue.
// The RoCC side (HorcruxRoCC.scala) keeps one instruction in flight, so result order is trivial.
module HorcruxRoCCAdapter (
  input  logic        clock,
  input  logic        reset,        // active high (Chisel)
  input  logic        req_valid,
  output logic        req_ready,
  input  logic [31:0] req_instr,
  input  logic [31:0] req_rs1,
  input  logic [31:0] req_rs2,
  input  logic [31:0] req_rs3,
  output logic        resp_valid,
  output logic [31:0] resp_data
);
  if_xif #(.X_NUM_RS(3)) xif ();

  // unused channels
  assign xif.compressed_valid = 1'b0;
  assign xif.compressed_req   = '0;
  assign xif.commit_valid     = 1'b0;
  assign xif.commit           = '0;
  assign xif.mem_ready        = 1'b0;
  assign xif.mem_resp         = '0;
  assign xif.mem_result_valid = 1'b0;
  assign xif.mem_result       = '0;

  // issue
  assign xif.issue_valid          = req_valid;
  assign xif.issue_req.instr      = req_instr;
  assign xif.issue_req.mode       = 2'b11;
  assign xif.issue_req.id         = '0;
  assign xif.issue_req.rs[0]      = req_rs1;
  assign xif.issue_req.rs[1]      = req_rs2;
  assign xif.issue_req.rs[2]      = req_rs3;
  assign xif.issue_req.rs_valid   = '1;
  assign xif.issue_req.ecs        = '0;
  assign xif.issue_req.ecs_valid  = 1'b1;
  assign req_ready                = xif.issue_ready;

  // result
  assign xif.result_ready = 1'b1;
  assign resp_valid       = xif.result_valid;
  assign resp_data        = xif.result.data;

  horcrux_top i_horcrux_top (
    .clk_i             (clock),
    .rst_ni            (~reset),
    .xif_compressed_if (xif),
    .xif_issue_if      (xif),
    .xif_commit_if     (xif),
    .xif_mem_if        (xif),
    .xif_mem_result_if (xif),
    .xif_result_if     (xif)
  );
endmodule
