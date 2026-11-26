#!/bin/sh
# Build the ML-KEM-768 test for the HORNET SoC.
# usage: sw/build.sh baseline|optimized   -> $OUT/sw/<variant>/mlkem768.{elf,imem.hex,dmem.hex}
set -e
. "$(dirname "$0")/../scripts/env.sh"
case $1 in baseline|optimized) ;; *) echo "usage: $0 baseline|optimized"; exit 1 ;; esac
make -s -C "$ROOT/sw" VARIANT=$1 HORNET="$HORNET" HORCRUX="$HORCRUX" OUT="$OUT/sw/$1" RISCV_PREFIX="$RV32"
echo "built $OUT/sw/$1/mlkem768.elf"
