# HORCRUX on Ibex

[HORCRUX](https://github.com/vlsi-lab/HORCRUX) is a post-quantum-crypto coprocessor written for the CV32E40PX
core's CORE-V-XIF interface. [Ibex](https://github.com/lowRISC/ibex) has no coprocessor interface, so this repo
adds a small one to Ibex (`patches/ibex-xif.patch`), attaches the unchanged HORCRUX to it in Ibex's Simple
System, and runs ML-KEM-768 with and without it on the `small` and `maxperf` Ibex configurations.

## Results (ML-KEM-768, cycles, Verilator, all KAT checks pass)

| Ibex config | Op | Simple System | + HORCRUX | Speedup | CV32E40PX (HORCRUX README) |
|---|---|---|---|---|---|
| small | KeyGen | 2,105,487 | 382,163 | 5.51× | 1,475k → 291k (5.1×) |
| small | Encaps | 2,371,409 | 443,271 | 5.35× | 1,602k → 325k (4.9×) |
| small | Decaps | 2,732,341 | 639,273 | 4.27× | 1,789k → 477k (3.8×) |
| maxperf | KeyGen | 1,570,734 | 309,378 | 5.08× | |
| maxperf | Encaps | 1,763,853 | 355,871 | 4.96× | |
| maxperf | Decaps | 2,030,962 | 505,734 | 4.02× | |

- The software is HORCRUX's own ML-KEM-768 code, unchanged (baseline and accelerated), built for rv32imc at -O2.
- The baseline build gives identical cycle counts on the stock Simple System, on the patched one (port off) and
  on the HORCRUX system: the patch changes nothing when the port is off, and adding HORCRUX does not slow down
  ordinary code.
- Data: `results/mlkem768_ibex_horcrux.csv`, program output in `results/logs/`.

## The coprocessor port (`patches/ibex-xif.patch`)

A subset of CORE-V-XIF (issue + result), enabled with the new `ibex_top` parameters:

| Parameter | |
|---|---|
| `XifEn` | 1 = port present (default 0: hardware and behaviour identical to stock Ibex) |
| `XifOpcodes` | bit *i* set: major opcode `{i, 2'b11}` goes to the coprocessor |
| `XifRs3Opcodes` | bit *i* set: those instructions also read rs3 = `instr[31:27]` |

For HORCRUX: `XifOpcodes` = 0x3B (R-type) and 0x6B (R4-type), `XifRs3Opcodes` = 0x6B.

How it works (all in `ibex_id_stage.sv`; the other files only pass the ports and parameters through):

1. **Decode.** An instruction with a selected opcode that Ibex's decoder finds illegal goes to the coprocessor
   instead of trapping. Ibex's own instructions are never redirected.
2. **Operands.** rs1/rs2 come through the normal read ports, with forwarding and load-hazard stalls. The register
   file has only two read ports, so for rs3 instructions port A first reads rs3 for one cycle and latches it.
3. **Issue and wait.** Handled like a multi-cycle multiply/divide: `xif_issue_valid` with the instruction and
   operands until `xif_issue_ready`, then wait for the `xif_result_valid` pulse. The result is latched, because
   HORCRUX has no `result_ready` and the writeback stage (maxperf) may be busy. Then it writes rd through the
   normal writeback path.
4. One coprocessor instruction is in flight at a time. An instruction the coprocessor never accepts stalls the
   core (HORCRUX does not reject unknown instructions, it just never raises `issue_ready`).

Not supported: `SecureIbex` (lockstep; the shadow core has no coprocessor connection, rejected at elaboration),
coprocessor memory access, and offloading compressed instructions (HORCRUX has none).

Files in the patch: `rtl/ibex_id_stage.sv` (the logic), `rtl/ibex_core.sv`, `rtl/ibex_top.sv`,
`rtl/ibex_top_tracing.sv` (ports and parameters), `rtl/ibex_lockstep.sv` and
`examples/simple_system/rtl/ibex_simple_system.sv` (port tied off).

## What is in here

| Path | |
|---|---|
| `ibex/` | submodule, lowRISC/ibex at c06c5bde (the commit used for our other Ibex measurements) |
| `../HORCRUX/` | submodule at the top of the repo (shared with horcrux-boom), vlsi-lab/HORCRUX, branch `locket`. RTL and ML-KEM sources are used unchanged. |
| `patches/ibex-xif.patch` | the coprocessor port (applied to `ibex/` by the scripts) |
| `rtl/ibex_simple_system.sv` | Ibex's Simple System top with HORCRUX attached (module name kept so Ibex's C++ testbench works unchanged; changes marked "HORCRUX") |
| `rtl/horcrux_xif_adapter.sv` | plain-port shell around the unchanged `horcrux_top` |
| `fusesoc/` | FuseSoC cores: `horcrux.core` (HORCRUX RTL + adapter + lint waiver), `simple_system_horcrux.core` |
| `scripts/` | `apply_patch.sh`, `build_sim.sh`, `run_sim.sh`, `env.sh` |
| `sw/` | `mlkem_bench.c` (KAT + mcycle/minstret per operation), `build.sh`, Simple System syscalls, counter header |
| `results/` | measured cycles and logs |

## Reproduce

Requirements: FuseSoC, Verilator 5, an RV32 GCC with newlib (`riscv32-unknown-elf-`), Python 3 with PyYAML,
libelf. Set paths in `local.env` if needed (see `scripts/env.sh`), e.g. `RV32=/opt/riscv32/bin/riscv32-unknown-elf-`.

```sh
git clone https://github.com/alibarisbozoglu/horcrux-core-evaluation.git
cd horcrux-core-evaluation
git submodule update --init HORCRUX horcrux-ibex/ibex
cd horcrux-ibex

scripts/build_sim.sh base small        # applies the patch first; also: base maxperf
scripts/build_sim.sh horcrux small     # also: horcrux maxperf
sw/build.sh baseline
sw/build.sh optimized
scripts/run_sim.sh base small baseline         # log: build/run/base_small_baseline.log
scripts/run_sim.sh horcrux small optimized     # log: build/run/horcrux_small_optimized.log
```

Each simulator builds in under a minute and each run takes 10 to 65 s.
