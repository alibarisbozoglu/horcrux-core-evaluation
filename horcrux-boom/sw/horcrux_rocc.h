/* HORCRUX instructions on the RoCC interface of BOOM (see generator/src/main/scala/HorcruxRoCC.scala).
 * Force-included (-include) into every C and assembly file of the ported HORCRUX software.
 *   hx_r  F, rd, rs1, rs2              == HORCRUX ".insn r 0x3b, 0x7, F, rd, rs1, rs2"
 *   hx_r4 f3, f2, rd, rs1, rs2, rs3    == HORCRUX ".insn r 0x6b, f3, f2, rd, rs1, rs2, rs3"
 * hx_r4 is two RoCC commands: SETRS3 (custom1, funct7 0x40, xs1 only) then the operation
 * (custom1, funct7 = f3 << 2 | f2). xd is always set, so every operation is answered (rd = x0 included). */
#ifndef HORCRUX_ROCC_H
#define HORCRUX_ROCC_H
#ifdef __ASSEMBLER__
.macro hx_r f7, rd, rs1, rs2
  .insn r 0x0b, 0x7, \f7, \rd, \rs1, \rs2
.endm
.macro hx_r4 f3, f2, rd, rs1, rs2, rs3
  .insn r 0x2b, 0x2, 0x40, x0, \rs3, x0
  .insn r 0x2b, 0x7, ((\f3) << 2) | (\f2), \rd, \rs1, \rs2
.endm
#else
/* GCC emits top-level asm before any function, so the macros are defined before the first use. */
__asm__(".macro hx_r f7, rd, rs1, rs2\n"
        "  .insn r 0x0b, 0x7, \\f7, \\rd, \\rs1, \\rs2\n"
        ".endm\n"
        ".macro hx_r4 f3, f2, rd, rs1, rs2, rs3\n"
        "  .insn r 0x2b, 0x2, 0x40, x0, \\rs3, x0\n"
        "  .insn r 0x2b, 0x7, ((\\f3) << 2) | (\\f2), \\rd, \\rs1, \\rs2\n"
        ".endm\n");
#endif
#endif
