# Common paths, sourced by the other scripts.
#   ROOT     this repo
#   CY       Chipyard checkout (default: the chipyard submodule). Set it in ./local.env to use an existing one.
#   HORCRUX  HORCRUX checkout (default: the HORCRUX submodule at the top of horcrux-core-evaluation)
#   OUT      binaries and logs (default: ./build)
#   CONDA_SH conda.sh to source if conda is not on PATH (scripts/build_sim.sh)
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$ROOT/local.env" ] && . "$ROOT/local.env"
CY=${CY:-$ROOT/chipyard}
HORCRUX=${HORCRUX:-$ROOT/../HORCRUX}
OUT=${OUT:-$ROOT/build}
