# Common paths, sourced by the other scripts.
#   ROOT     this folder (horcrux-rocket)
#   BOOM     horcrux-boom folder: the RoCC generator, Chipyard patch and ML-KEM port are shared with it
#   CY       Chipyard checkout (default: horcrux-boom's chipyard submodule). Set it in ./local.env to use an
#            existing one (the same one as in horcrux-boom/local.env).
#   HORCRUX  HORCRUX checkout (default: the HORCRUX submodule at the top of horcrux-core-evaluation)
#   OUT      binaries, RV32 runtime and logs (default: ./build)
#   RV32     RV32 GCC prefix with newlib, for the RV32 builds (default: riscv32-unknown-elf- on PATH)
#   CONDA_SH conda.sh to source if conda is not on PATH (scripts/build_sim.sh)
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$ROOT/local.env" ] && . "$ROOT/local.env"
BOOM=$(cd "$ROOT/../horcrux-boom" && pwd)
CY=${CY:-$BOOM/chipyard}
HORCRUX=${HORCRUX:-$ROOT/../HORCRUX}
OUT=${OUT:-$ROOT/build}
RV32=${RV32:-riscv32-unknown-elf-}
