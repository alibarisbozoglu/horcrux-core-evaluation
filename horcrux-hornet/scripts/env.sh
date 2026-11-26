# Common paths, sourced by the other scripts.
#   ROOT     this folder (horcrux-hornet)
#   HORNET   HORNET checkout (default: the hornet submodule, with patches/hornet-xif.patch applied)
#   HORCRUX  HORCRUX checkout (default: the HORCRUX submodule at the top of horcrux-core-evaluation)
#   OUT      simulators, binaries and logs (default: ./build)
#   RV32     RV32 GCC prefix (default: riscv32-unknown-elf- on PATH)
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$ROOT/local.env" ] && . "$ROOT/local.env"
HORNET=${HORNET:-$ROOT/hornet}
HORCRUX=${HORCRUX:-$ROOT/../HORCRUX}
OUT=${OUT:-$ROOT/build}
RV32=${RV32:-riscv32-unknown-elf-}
