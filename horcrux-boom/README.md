# HORCRUX on SmallBOOM

[HORCRUX](https://github.com/vlsi-lab/HORCRUX) is a post-quantum-crypto coprocessor written for the CV32E40PX
core's CORE-V-XIF interface. This folder connects it, unchanged, to Chipyard's SmallBOOM through RoCC and runs
ML-KEM-768 on BOOM with and without it.

| Config | What it is |
|---|---|
| `SmallBoomV3Config` | stock Chipyard SmallBOOM (reference) |
| `SmallBoomV3HorcruxConfig` | the same + `horcrux.WithHorcruxRoCC` (HORCRUX on RoCC custom0/custom1) |

## Results (ML-KEM-768, cycles, Verilator, all KAT checks pass)

| | SmallBOOM | SmallBOOM + HORCRUX | Speedup |
|---|---|---|---|
| KeyGen | 845,843 | 375,647 | 2.25× |
| Encaps | 1,024,353 | 424,182 | 2.41× |
| Decaps | 1,260,493 | 594,495 | 2.12× |

Data in `results/mlkem768_boom_horcrux.csv`, simulator logs in `results/logs/`. The software-only build runs
on the HORCRUX config with the same cycle counts (within 0.03 %).

The HORCRUX paper reports 5.1× / 4.9× / 3.8× on CV32E40PX. The speedup here is lower because BOOM's software
baseline is faster, and because RoCC commands are sent at commit with this adapter keeping one in flight, so
the pipeline drains at every HORCRUX instruction (IPC 0.97 → 0.61).

## What is in here

| Path | |
|---|---|
| `../HORCRUX/` | submodule at the top of the repo (shared with horcrux-ibex), vlsi-lab/HORCRUX, branch `locket`. RTL and ML-KEM sources are used unchanged. |
| `chipyard/` | submodule, ucb-bar/chipyard at tag 1.15.0 (BOOM and rocket-chip are pinned by it, unchanged) |
| `generator/` | the Chipyard generator that `scripts/install.sh` copies to `chipyard/generators/horcrux` |
| `generator/src/main/scala/HorcruxRoCC.scala` | RoCC module, BlackBox, `WithHorcruxRoCC` config fragment |
| `generator/src/main/resources/vsrc/HorcruxRoCCAdapter.sv` | plain-port shell around the unchanged `horcrux_top` |
| `generator/chipyard/HorcruxConfigs.scala` | `SmallBoomV3HorcruxConfig` |
| `patches/chipyard-build-sbt.patch` | the only change to Chipyard: registers `horcrux` as an optional generator |
| `patches/chipyard-sysroot-2.39.patch` | optional toolchain-environment fix, only if Chipyard's conda setup fails on your host |
| `scripts/` | `setup_chipyard.sh`, `install.sh`, `gen_rtl.sh`, `build_sim.sh`, `run_sim.sh`, `env.sh` |
| `sw/` | ML-KEM-768 test: `mlkem_bench.c` (KAT + mcycle/minstret), `horcrux_rocc.h` (instruction macros), `port_mlkem.py` (RV32 → RV64 RoCC port of HORCRUX's sources), `bench_chipyard.h`, `build.sh` |
| `results/` | measured cycles and logs |

## How it fits into Chipyard

Chipyard builds Scala generators from `chipyard/generators/<name>`. Optional ones (like `caliptra-aes-acc`) are
listed in `build.sbt` and only used if their folder is a git checkout. `scripts/install.sh` therefore:

1. copies `generator/` to `chipyard/generators/horcrux` and makes that copy a small local git repo;
2. writes `horcrux_rocc.sv` there: the HORCRUX RTL (packages first) + the adapter in one file (`gen_rtl.sh`);
3. applies `patches/chipyard-build-sbt.patch`.

It is idempotent; run it again after changing anything in `generator/`. A config then adds HORCRUX with one
line: `new horcrux.WithHorcruxRoCC ++ new SmallBoomV3Config`.

## Instruction encoding

| RoCC | HORCRUX |
|---|---|
| custom0, funct7 = F | R-type `.insn r 0x3b, 0x7, F` |
| custom1, funct7 = 0x40, xs1 only (SETRS3) | stores rs1 as rs3 of the next R4 instruction |
| custom1, funct7 = f3<<2 \| f2 | R4-type `.insn r 0x6b, f3, f2` with rs3 = the stored value |

RoCC passes two source registers, so three-operand instructions are sent as two commands. Operands are the low
32 bits; results are sign-extended to 64 bits. xd is always set, so every command gets a response.

## Reproduce

```sh
git clone https://github.com/alibarisbozoglu/horcrux-core-evaluation.git
cd horcrux-core-evaluation
git submodule update --init HORCRUX
cd horcrux-boom

# Chipyard: either a fresh one in ./chipyard (large, slow) ...
scripts/setup_chipyard.sh
# ... or an existing Chipyard 1.15.0 elsewhere:
echo 'CY=/path/to/chipyard' > local.env

scripts/install.sh
scripts/build_sim.sh SmallBoomV3Config
scripts/build_sim.sh SmallBoomV3HorcruxConfig
sw/build.sh baseline
sw/build.sh optimized
scripts/run_sim.sh SmallBoomV3Config baseline           # log: build/baseline/SmallBoomV3Config.log
scripts/run_sim.sh SmallBoomV3HorcruxConfig optimized   # log: build/optimized/SmallBoomV3HorcruxConfig.log
```

Each run takes about 7 (HORCRUX) to 30 (baseline) minutes. Every Chipyard HTIF run ends with
`*** FAILED *** (tohost = 5)` and exit 255 after the program has printed its result; the `result PASS|FAIL`
line is what counts.
