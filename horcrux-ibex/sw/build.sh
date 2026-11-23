#!/bin/sh
# Build the ML-KEM-768 test for the Ibex Simple System.
# usage: sw/build.sh baseline|optimized
#   baseline : HORCRUX repo's software-only sources, unchanged   -> runs on both systems
#   optimized: HORCRUX repo's accelerated sources, unchanged     -> needs the HORCRUX system
# Both: same harness (mlkem_bench.c), rv32imc, -O2, Ibex Simple System runtime (crt0, SIM_CTRL output),
# 1 MiB RAM: code + data from 0x100000, 64 KiB stack at the top.
set -e
. "$(dirname "$0")/../scripts/env.sh"
V=$1
H=$HORCRUX/sw/applications/pqc
ISW=$IBEX/examples/sw/simple_system/common
CC=${RV32}gcc
B=$OUT/sw/$V
case $V in
baseline)  SRC=$H/baseline/KEM/ML-KEM/ml-kem-768 ;;
optimized) SRC=$H/optimized/KEM/ML-KEM/ml-kem-768 ;;
*) echo "usage: $0 baseline|optimized"; exit 1 ;;
esac
mkdir -p $B
sed -E -e 's/^([[:space:]]*ram[[:space:]]*:).*/\1 ORIGIN = 0x100000, LENGTH = 0xF0000/' \
       -e 's/^([[:space:]]*stack[[:space:]]*:).*/\1 ORIGIN = 0x1F0000, LENGTH = 0x10000/' $ISW/link.ld > $B/link.ld
FILES=$(ls $SRC/*.c $SRC/*.S 2>/dev/null | grep -v -E '/(main|randombytes)\.c$')
$CC -march=rv32imc_zicsr_zifencei -mabi=ilp32 -mcmodel=medany -static -O2 -std=gnu11 \
  -I$SRC -I$ROOT/sw -I$ISW -DHX_VARIANT="\"$V\"" \
  -o $B/mlkem768.elf $ROOT/sw/mlkem_bench.c $FILES $ISW/simple_system_common.c $ISW/crt0.S $ROOT/sw/ibex_syscalls.c \
  -nostartfiles -specs=nano.specs -T $B/link.ld -Wl,--no-warn-rwx-segments -lgcc
${RV32}size $B/mlkem768.elf
echo "built $B/mlkem768.elf"
