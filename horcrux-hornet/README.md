# HORCRUX on HORNET

[HORCRUX](https://github.com/vlsi-lab/HORCRUX) is a post-quantum-crypto coprocessor written for the CV32E40PX
core's CORE-V-XIF interface. [HORNET](https://github.com/GSTL-ITU/HORNET-RV32IMF) (5-stage RV32I[M][F] pipeline,
Verilog) has no coprocessor interface, so this folder adds a small one to HORNET's EX stage
(`patches/hornet-xif.patch`), attaches the unchanged HORCRUX to it in HORNET's SoC, and runs ML-KEM-768 with and
without it.

## Results (ML-KEM-768, cycles, Verilator, all KAT checks pass)

| HORNET ISA | Op | HORNET SoC | + HORCRUX | Speedup | CV32E40PX (HORCRUX README) |
|---|---|---|---|---|---|
| rv32im | KeyGen | 1,601,350 | 315,194 | 5.08× | 1,475k → 291k (5.1×) |
| rv32im | Encaps | 1,814,013 | 360,032 | 5.04× | 1,602k → 325k (4.9×) |
| rv32im | Decaps | 2,099,179 | 514,796 | 4.08× | 1,789k → 477k (3.8×) |

- rv32imf (HORNET's default, with the FPU) gives exactly the same cycles: the code is integer only.
- The software is HORCRUX's own ML-KEM-768 code, unchanged (baseline and accelerated), built for rv32im at -O2
  with HORNET's own software flow (`hornet/sw/common.mk`: crt0, newlib on the UART, linker script). It fits
  HORNET's default memories (64 KiB IMEM + 64 KiB DMEM).
- The baseline build gives identical cycle counts on the stock SoC, on the patched one (port off) and on the
  HORCRUX SoC.
- Data: `results/mlkem768_hornet_horcrux.csv`, program output in `results/logs/`.

## The coprocessor port (`patches/hornet-xif.patch`)

A subset of CORE-V-XIF (issue + result), enabled with new `hornet_core` parameters:

| Parameter | |
|---|---|
| `XIF_EN` | 1 = port present (default 0: hardware and behaviour identical to stock HORNET) |
| `XIF_OPCODES` | bit *i* set: major opcode `{i, 2'b11}` goes to the coprocessor |
| `XIF_RS3_OPCODES` | bit *i* set: those instructions also read rs3 = `instr[31:27]` |

For HORCRUX: `XIF_OPCODES` = 0x3B (R-type) and 0x6B (R4-type), `XIF_RS3_OPCODES` = 0x6B.

How it works:

1. **Decode** (`control_unit.v`). An instruction with a selected opcode that HORNET's decoder finds illegal is
   marked as a coprocessor instruction instead of trapping: rs1, rs2 (and rs3) from the integer register file,
   integer rd. HORNET's own instructions are never redirected.
2. **Operands.** HORNET's register file already has a third read port (for FMA), but it read only the float
   registers; it now reads the integer file when `rs3_fp` is 0 (`regfile.v`), and the hazard unit's rs3
   load-use check and forwarding compare that flag instead of assuming a float register (`hazard_unit.v`).
3. **Issue and wait** (`ex_stage.v`). The instruction is handled in EX like the divider and the FPU: `busy`
   holds the pipeline while `xif_issue_valid` offers the instruction and forwarded operands until
   `xif_issue_ready`, then until the `xif_result_valid` pulse. The result goes into EX/MEM in that cycle, or is
   latched if memory holds the pipeline (HORCRUX has no `result_ready`), and is written to rd through the normal
   path (forwarded from MEM/WB like an ALU result).
4. One coprocessor instruction is in flight at a time. The instruction is offered only while the pipeline
   neither holds nor flushes, so an accepted instruction retires, except when an older load/store gets a data
   bus error after the accept; the coprocessor has then executed it and its result is dropped (the benchmark
   never does this, and this path is not exercised by any test here). An instruction the coprocessor never
   accepts stalls the core (HORCRUX does not reject unknown instructions, it just never raises `issue_ready`).

Not supported: coprocessor memory access, RVFI/riscv-formal for coprocessor instructions (the formal wrapper
ties the port off).

Files in the patch: `rtl/core/control_unit.v`, `regfile.v`, `hazard_unit.v`, `ex_stage.v` (the logic),
`id_stage.v`, `hornet_core.v` (signals and parameters), `rtl/soc/hornet_soc.v`, `tb/hornet_tb.sv`,
`verif/formal/wrapper.sv` (port tied off).

Checked with the port off: HORNET's lint (`-Wall`, rv32i/rv32im/rv32imf), riscv-tests on the core testbench
(rv32imf 75/75, rv32im 64/64, without Spike), HORNET's SoC software tests (6/6). With the port on: lint of the
core (`-Wall`), the ML-KEM KAT runs above.

## What is in here

| Path | |
|---|---|
| `hornet/` | submodule, GSTL-ITU/HORNET-RV32IMF `main` at 59412a9 |
| `../HORCRUX/` | submodule at the top of the repo (shared), vlsi-lab/HORCRUX, branch `locket`. RTL and ML-KEM sources are used unchanged. |
| `patches/hornet-xif.patch` | the coprocessor port (applied to `hornet/` by the scripts) |
| `rtl/hornet_soc.v` | HORNET's SoC with HORCRUX attached (module name kept so HORNET's `tb/soc_tb.sv` works unchanged; changes marked "HORCRUX") |
| `rtl/horcrux_xif_adapter.sv` | plain-port shell around the unchanged `horcrux_top` (same as in horcrux-ibex) |
| `scripts/` | `apply_patch.sh`, `build_sim.sh`, `run_sim.sh`, `env.sh` |
| `sw/` | `Makefile` (on HORNET's `common.mk`), `build.sh`, `mlkem_bench.c` (KAT + mcycle/minstret per operation, same as horcrux-ibex), counter header |
| `results/` | measured cycles and logs |

Both HORCRUX and HORNET have a module called `id_stage`. `build_sim.sh` compiles HORCRUX's as
`horcrux_id_stage`, using renamed copies of the two HORCRUX files that name it (in the build folder).

## Reproduce

Requirements: Verilator 5, an RV32 GCC with newlib and an `rv32im`/`ilp32` multilib (`riscv32-unknown-elf-`),
Python 3 with pyelftools. HORNET's Docker image is not needed. Set paths in `local.env` if needed (see
`scripts/env.sh`), e.g. `RV32=/opt/riscv32/bin/riscv32-unknown-elf-`.

```sh
git clone https://github.com/alibarisbozoglu/horcrux-core-evaluation.git
cd horcrux-core-evaluation
git submodule update --init HORCRUX horcrux-hornet/hornet
cd horcrux-hornet

scripts/build_sim.sh base rv32im        # applies the patch first; isa: rv32i | rv32im | rv32imf
scripts/build_sim.sh horcrux rv32im
sw/build.sh baseline
sw/build.sh optimized
scripts/run_sim.sh base rv32im baseline          # log: build/run/base_rv32im_baseline.log
scripts/run_sim.sh horcrux rv32im optimized      # log: build/run/horcrux_rv32im_optimized.log
```

Each simulator builds in under 30 s and each run takes 4 to 45 s. Waveforms: `TRACE=--trace-fst
scripts/build_sim.sh ...`, then pass `+waves=<file.fst>` to the simulator. With HORCRUX, the traced build used
more than 19 GB and was stopped by the out-of-memory killer on a 32 GB machine (without tracing: 0.45 GB).
