#!/bin/sh
# Chipyard's toolchain has no RV32 runtime. Build Chipyard's libgloss-htif (toolchains/libgloss) for rv32imac /
# ilp32 with the RV32 GCC ($RV32), into $OUT/htif32-inst. Used by sw/build.sh rv32 (called automatically).
set -e
. "$(dirname "$0")/env.sh"
[ -f "$OUT/htif32-inst/lib/libgloss_htif.a" ] && { echo "htif32 runtime present"; exit 0; }
SRC=$CY/toolchains/libgloss
[ -x "$SRC/configure" ] || { echo "no $SRC (git -C $CY submodule update --init toolchains/libgloss)"; exit 1; }
B=$OUT/htif32-build; rm -rf "$B"; mkdir -p "$B"; cd "$B"
PATH=$(dirname "${RV32}gcc"):$PATH "$SRC/configure" --prefix="$OUT/htif32-inst" --host=riscv32-unknown-elf \
  --disable-multilib CFLAGS="-O2 -march=rv32imac_zicsr -mabi=ilp32 -mcmodel=medany" \
  CCASFLAGS="-march=rv32imac_zicsr -mabi=ilp32" > configure.log
# searchdirs: libgloss's install checks that libdir is in GCC's default library path; sw/build.sh passes it
# with -B/-L instead, so the check is pointed at libdir.
PATH=$(dirname "${RV32}gcc"):$PATH make -j4 > make.log
PATH=$(dirname "${RV32}gcc"):$PATH make install searchdirs="$OUT/htif32-inst/lib" > install.log
echo "built $OUT/htif32-inst"
