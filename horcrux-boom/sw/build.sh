#!/bin/sh
# Build the ML-KEM-768 test for BOOM.
# usage: sw/build.sh baseline|optimized
#   baseline : HORCRUX repo's software-only sources, unchanged         -> runs on SmallBoomV3Config
#   optimized: HORCRUX repo's accelerated sources, port_mlkem.py'd     -> needs SmallBoomV3HorcruxConfig
# Both: same harness (mlkem_bench.c), rv64imafdc, -O2, Chipyard toolchain + HTIF (htif_nano.specs).
set -e
. "$(dirname "$0")/../scripts/env.sh"
V=$1
HERE=$ROOT/sw
H=$HORCRUX/sw/applications/pqc
CC=$CY/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gcc
B=$OUT/$V
mkdir -p $B
case $V in
baseline)  SRC=$H/baseline/KEM/ML-KEM/ml-kem-768; INC="" ;;
optimized) SRC=$B/src; INC="-include $HERE/horcrux_rocc.h"
           python3 $HERE/port_mlkem.py $H/optimized/KEM/ML-KEM/ml-kem-768 $SRC ;;
*) echo "usage: $0 baseline|optimized"; exit 1 ;;
esac
FILES=$(ls $SRC/*.c $SRC/*.S 2>/dev/null | grep -v -E '/(main|randombytes)\.c$')
$CC -march=rv64imafdc_zicsr -mabi=lp64d -mcmodel=medany -O2 -std=gnu11 -fno-common -fno-builtin-printf \
  -specs=htif_nano.specs -static -I$SRC -I$HERE -DHX_VARIANT="\"$V\"" $INC \
  -o $B/mlkem768.riscv $HERE/mlkem_bench.c $FILES
$CY/.conda-env/riscv-tools/bin/riscv64-unknown-elf-size $B/mlkem768.riscv
echo "built $B/mlkem768.riscv"
