#!/bin/sh
# Build a Verilator model of the HORNET SoC testbench (HORNET's tb/soc_tb.sv, unchanged).
# usage: scripts/build_sim.sh base|horcrux [isa] [jobs]
#   base    : HORNET's SoC (patched core, coprocessor port off = stock behaviour)
#   horcrux : rtl/hornet_soc.v (HORNET's SoC + HORCRUX on the coprocessor port)
#   isa     : rv32i | rv32im | rv32imf (default rv32im), as in HORNET's Makefile
# Same Verilator flags and memory sizes (64 KiB IMEM + 64 KiB DMEM) as HORNET's `make soc-sim`.
# Output: $OUT/sim_<system>_<isa>/Vsoc_tb
set -e
. "$(dirname "$0")/env.sh"
SYS=$1; ISA=${2:-rv32im}; J=${3:-6}
TRACE=${TRACE-}   # TRACE=--trace-fst for waveforms (+waves=<file> at run time); off by default: HORCRUX tracing needs a lot of memory
case $ISA in rv32i) M=0 F=0 ;; rv32im) M=1 F=0 ;; rv32imf) M=1 F=1 ;; *) echo "bad isa $ISA"; exit 1 ;; esac
"$ROOT/scripts/apply_patch.sh"
cd "$HORNET"
SRCS=$(make -s -p HORNET_CONTAINER=1 -f Makefile 2>/dev/null | sed -n -e 's/^CORE_SRCS = //p' -e 's/^FPU_SRCS  *= //p' -e 's/^SOC_SRCS  *= //p' | head -3 | tr '\n' ' ')
[ -n "$SRCS" ] || { echo "could not read the source list from $HORNET/Makefile"; exit 1; }
W=$OUT/sim_${SYS}_$ISA
mkdir -p "$W"
case $SYS in
base) EXTRA= ;;
horcrux)
  # HORCRUX's RTL, unchanged, except that its module id_stage is compiled as horcrux_id_stage (HORNET has an
  # id_stage too): renamed copies of the two files that name it.
  HC=$HORCRUX/hw/ip/coprocessors
  R=$W/horcrux_renamed; mkdir -p "$R"
  sed -E 's/^(\s*module\s+)id_stage\b/\1horcrux_id_stage/' "$HC/id_stage.sv" > "$R/id_stage.sv"
  sed -E 's/^(\s*)id_stage(\s+id_stage_i\b)/\1horcrux_id_stage\2/' "$HC/horcrux_top.sv" > "$R/horcrux_top.sv"
  grep -q "module horcrux_id_stage" "$R/id_stage.sv" && grep -q "horcrux_id_stage id_stage_i" "$R/horcrux_top.sv" \
    || { echo "renaming HORCRUX id_stage failed"; exit 1; }
  HV=$HORCRUX/hw/vendor/x-heep/hw/vendor/openhwgroup_cv32e40x/rtl
  EXTRA="$HV/include/cv32e40x_pkg.sv $HV/if_xif.sv $HC/include/cv32e40px_core_v_xif_pkg.sv $HC/include/cv32e40px_pkg.sv
    $HC/include/horcrux_pkg.sv $HC/keccak/pkg_keccak.sv $HC/keccak/keccak_cu.sv $HC/keccak/keccak_dp.sv $HC/keccak/keccak_f.sv
    $HC/keccak/keccak_round_constants_gen.sv $HC/keccak/keccak_round.sv $HC/barrett.sv $HC/cbd_eta.sv $HC/chain_lengths.sv
    $HC/commit_stage.sv $HC/fpr.sv $HC/horcrux_register.sv $HC/horcrux.sv $R/horcrux_top.sv $R/id_stage.sv
    $HC/multiplier_tree.sv $HC/sampler.sv $HC/shared_multiplication_logic.sv $HC/sphincs_ops.sv $HC/unified_mul_32x32.sv
    $ROOT/rtl/horcrux_xif_adapter.sv"
  SRCS=$(echo "$SRCS" | sed "s|rtl/soc/hornet_soc.v|$ROOT/rtl/hornet_soc.v|") ;;
*) echo "usage: $0 base|horcrux [rv32i|rv32im|rv32imf] [jobs]"; exit 1 ;;
esac
# flags of HORNET's Makefile (VERILATOR_FLAGS, SIM_SOC)
verilator --binary --timing -j "$J" -Wno-fatal -Wno-lint -Wno-style +1364-2005ext+v $TRACE --timescale 1ns/1ps \
  -Irtl/core -Irtl/fpu --top-module soc_tb --Mdir "$W" -o Vsoc_tb -GRV_M=$M -GRV_F=$F \
  -GIMEM_SIZE=65536 -GDMEM_SIZE=65536 -GBOOT_ADDR=0 $EXTRA $SRCS tb/soc_tb.sv > "$W.build.log" 2>&1 \
  || { tail -30 "$W.build.log"; exit 1; }
grep -E "^%(Warning|Error)" "$W.build.log" | sed 's/:.*//' | sort | uniq -c || true
echo "built $W/Vsoc_tb"
