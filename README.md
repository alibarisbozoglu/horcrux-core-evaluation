# HORCRUX core evaluation

[HORCRUX](https://github.com/vlsi-lab/HORCRUX) is a post-quantum-crypto coprocessor written for the CV32E40PX
core's CORE-V-XIF interface. This repo attaches the unchanged HORCRUX to other RISC-V cores and measures
ML-KEM-768 on each core with and without it. Each folder has its own README.

| Folder | Core | Connection | ML-KEM-768 speedup (KeyGen / Encaps / Decaps) |
|---|---|---|---|
| `horcrux-boom` | Chipyard SmallBOOM | RoCC adapter | 2.25× / 2.41× / 2.12× |
| `horcrux-ibex` | Ibex small / maxperf | coprocessor port added to Ibex | 5.51× / 5.35× / 4.27× (small), 5.08× / 4.96× / 4.02× (maxperf) |

HORCRUX's own numbers on CV32E40PX: 5.1× / 4.9× / 3.8×.

## Submodules

| Path | Upstream | Needed for |
|---|---|---|
| `HORCRUX` | vlsi-lab/HORCRUX, branch `locket` | both |
| `horcrux-ibex/ibex` | lowRISC/ibex at c06c5bde | horcrux-ibex |
| `horcrux-boom/chipyard` | ucb-bar/chipyard 1.15.0 | horcrux-boom (large; or use an existing Chipyard, see horcrux-boom/README.md) |

```sh
git clone https://github.com/alibarisbozoglu/horcrux-core-evaluation.git
cd horcrux-core-evaluation
git submodule update --init HORCRUX horcrux-ibex/ibex   # Chipyard: horcrux-boom/scripts/setup_chipyard.sh
```

Do not use `git clone --recurse-submodules`: it would also fetch Chipyard and all of its own submodules.
