# HORCRUX on Rocket

[HORCRUX](https://github.com/vlsi-lab/HORCRUX) is a post-quantum-crypto coprocessor written for the CV32E40PX
core's CORE-V-XIF interface. This folder attaches it, unchanged, to Chipyard's Rocket core through RoCC, in an
RV64 and an RV32 Rocket, and runs ML-KEM-768 with and without it. The RoCC module is the one from
`../horcrux-boom` (it works for both XLENs); this folder adds only the two Rocket configs, the RV32 software
flow and the results.

| Config | What it is |
|---|---|
| `RocketConfig` | stock Chipyard Rocket, RV64GC (reference) |
| `RocketHorcruxConfig` | the same + `horcrux.WithHorcruxRoCC` |
| `RV32RocketConfig` | stock Chipyard Rocket, RV32IMAC (reference) |
| `RV32RocketHorcruxConfig` | the same + `horcrux.WithHorcruxRoCC` |

## Results (ML-KEM-768, cycles, Verilator, all KAT checks pass)

| Rocket | Op | Software | + HORCRUX | Speedup |
|---|---|---|---|---|
| RV64 | KeyGen | 1,041,935 | 358,866 | 2.90× |
| RV64 | Encaps | 1,266,953 | 413,416 | 3.06× |
| RV64 | Decaps | 1,596,196 | 583,105 | 2.74× |
| RV32 | KeyGen | 1,715,309 | 354,721 | 4.84× |
| RV32 | Encaps | 1,952,176 | 403,008 | 4.84× |
| RV32 | Decaps | 2,288,900 | 570,229 | 4.01× |

- The software-only build gives exactly the same cycle counts on the HORCRUX configs as on the stock ones.
- With HORCRUX, RV32 and RV64 Rocket take almost the same number of cycles. The software-only RV64 build is
  faster, so the RV64 speedup is lower.
- HORCRUX's own numbers on CV32E40PX: 5.1× / 4.9× / 3.8×.
- Data: `results/mlkem768_rocket_horcrux.csv`. Simulator logs: `results/logs/<xlen>-<software>_<Config>.log`.

## How it is connected

The connection is the same as in horcrux-boom (see its README):

- **Generator.** `horcrux-boom/generator` becomes Chipyard's `generators/horcrux`, with its build.sbt patch.
  `scripts/install.sh` runs horcrux-boom's install.sh first. It then copies
  `generator/chipyard/HorcruxRocketConfigs.scala` next to BOOM's configs.
- **RoCC adapter.** HORCRUX instructions go through RoCC custom0/custom1. Three-operand instructions are sent as
  two commands.
- **XLEN.** The RoCC module sign-extends the 32-bit result to the tile's XLEN, so it does nothing on RV32. This
  is the only change made to horcrux-boom for Rocket. The RV64 hardware is the same as before.
- **Unchanged parts.** Rocket, rocket-chip and the rest of Chipyard are not touched.

## Software

| | RV64 | RV32 |
|---|---|---|
| ISA / ABI | rv64imafdc / lp64d | rv32imac / ilp32 |
| Compiler | Chipyard's riscv64-unknown-elf-gcc | an RV32 GCC with newlib (`$RV32`) |
| Runtime | Chipyard's HTIF (`htif_nano.specs`) | Chipyard's libgloss-htif, built for RV32 by `scripts/build_htif32.sh` (Chipyard's toolchain has no RV32 runtime) |
| HORCRUX sources | `port_mlkem.py` (RV32 → RV64 + RoCC) | `port_mlkem.py --rv32` (RoCC only; no RV64 stack-frame changes) |
| Harness | horcrux-boom's `mlkem_bench.c` | horcrux-ibex's `mlkem_bench.c` (the same test; prints with `%lu`, because RV32 newlib-nano has no `%llu`) |

Both use HORCRUX's ML-KEM-768 sources at -O2: the software-only build unchanged, the accelerated build ported to
RoCC. The ported RV32 binary uses only custom0/custom1 and has no 0x3B/0x6B instructions left.

## What is in here

| Path | |
|---|---|
| `generator/chipyard/HorcruxRocketConfigs.scala` | `RocketHorcruxConfig`, `RV32RocketHorcruxConfig` |
| `scripts/` | `install.sh`, `build_sim.sh`, `run_sim.sh`, `build_htif32.sh`, `env.sh` |
| `sw/build.sh` | builds the ML-KEM test (sources, macros and port script from horcrux-boom/sw, horcrux-ibex/sw, HORCRUX) |
| `results/` | measured cycles and logs |

## Reproduce

You need a Chipyard 1.15.0, set up as in horcrux-boom: either `horcrux-boom/chipyard`, or
`CY=/path/to/chipyard` in `local.env`. For RV32 you also need an RV32 GCC with newlib,
`RV32=/path/to/bin/riscv32-unknown-elf-` in `local.env`, and Chipyard's `toolchains/libgloss` submodule.

```sh
cd horcrux-core-evaluation/horcrux-rocket
scripts/install.sh
scripts/build_sim.sh RocketHorcruxConfig          # and RocketConfig, RV32RocketConfig, RV32RocketHorcruxConfig
scripts/build_sim.sh RV32RocketHorcruxConfig
sw/build.sh rv64 baseline;  sw/build.sh rv64 optimized
sw/build.sh rv32 baseline;  sw/build.sh rv32 optimized
scripts/run_sim.sh RocketConfig rv64 baseline              # log: build/rv64-baseline/RocketConfig.log
scripts/run_sim.sh RocketHorcruxConfig rv64 optimized
scripts/run_sim.sh RV32RocketConfig rv32 baseline
scripts/run_sim.sh RV32RocketHorcruxConfig rv32 optimized
```

Runs take about 20 minutes with HORCRUX and about 60 minutes without. They end with
`*** FAILED *** (tohost = 5)` and exit 255. As in horcrux-boom, this happens after the program has printed its
result; the `result PASS|FAIL` line is what counts.
