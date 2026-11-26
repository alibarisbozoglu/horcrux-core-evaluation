#!/bin/sh
# Build the ML-KEM-768 test for Rocket.
# usage: sw/build.sh rv32|rv64 baseline|optimized      -> $OUT/<xlen>-<variant>/mlkem768.riscv
#   baseline : HORCRUX repo's software-only sources, unchanged      -> runs on RocketConfig / RV32RocketConfig
#   optimized: HORCRUX repo's accelerated sources, port_mlkem.py'd  -> needs Rocket(RV32)HorcruxConfig
#   rv64: rv64imafdc, Chipyard toolchain + HTIF (same as horcrux-boom)
#   rv32: rv32imac, RV32 GCC/newlib ($RV32) + Chipyard's libgloss-htif built for RV32 (scripts/build_htif32.sh)
# RoCC macros and port script: horcrux-boom/sw (horcrux_rocc.h, port_mlkem.py). Harness: rv64 = horcrux-boom's
# mlkem_bench.c (prints %llu, as on BOOM); rv32 = the copy in horcrux-ibex/sw (= horcrux-hornet/sw), which prints
# %lu, because the RV32 newlib-nano printf has no %llu. Same flow, test vector and counter code.
set -e
. "$(dirname "$0")/../scripts/env.sh"
X=$1; V=$2
BS=$BOOM/sw
H=$HORCRUX/sw/applications/pqc
B=$OUT/$X-$V
case $X in
rv64) CC=$CY/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gcc; PORT=; HS=$BS
      ARCH="-march=rv64imafdc_zicsr -mabi=lp64d"; LINK="-specs=htif_nano.specs" ;;
rv32) "$ROOT/scripts/build_htif32.sh"; CC=${RV32}gcc; PORT=--rv32; HL=$OUT/htif32-inst/lib; HS=$ROOT/../horcrux-ibex/sw
      ARCH="-march=rv32imac_zicsr_zifencei -mabi=ilp32"; LINK="-B$HL/ -L$HL -specs=htif_nano.specs" ;;
*) echo "usage: $0 rv32|rv64 baseline|optimized"; exit 1 ;;
esac
mkdir -p $B
case $V in
baseline)  SRC=$H/baseline/KEM/ML-KEM/ml-kem-768; INC="" ;;
optimized) SRC=$B/src; INC="-include $BS/horcrux_rocc.h"
           python3 $BS/port_mlkem.py $H/optimized/KEM/ML-KEM/ml-kem-768 $SRC $PORT ;;
*) echo "usage: $0 rv32|rv64 baseline|optimized"; exit 1 ;;
esac
FILES=$(ls $SRC/*.c $SRC/*.S 2>/dev/null | grep -v -E '/(main|randombytes)\.c$')
$CC $ARCH -mcmodel=medany -O2 -std=gnu11 -fno-common -fno-builtin-printf $LINK -static \
  -I$SRC -I$HS -DHX_VARIANT="\"$V\"" $INC -o $B/mlkem768.riscv $HS/mlkem_bench.c $FILES
${CC%gcc}size $B/mlkem768.riscv
echo "built $B/mlkem768.riscv"
