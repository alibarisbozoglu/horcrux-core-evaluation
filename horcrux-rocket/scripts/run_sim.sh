#!/bin/sh
# Run an ML-KEM-768 build on a Chipyard Verilator simulator (tile + L2 + DRAMSim2, program loaded with +loadmem).
# usage: run_sim.sh <Config> rv32|rv64 baseline|optimized      log: $OUT/<xlen>-<build>/<Config>.log
# Every Chipyard HTIF run ends with "*** FAILED *** (tohost = 5)" / exit 255 after the program has printed its
# result (as in horcrux-boom); the "result PASS|FAIL" line is what counts.
. "$(dirname "$0")/env.sh"
CFG=$1; D=$OUT/$2-$3; L=$D/$CFG.log
[ -f "$D/mlkem768.riscv" ] || { echo "no program $D/mlkem768.riscv (sw/build.sh $2 $3)"; exit 1; }
s=$(date +%s)
$CY/sims/verilator/simulator-chipyard.harness-$CFG +permissive +dramsim \
  +dramsim_ini_dir=$CY/generators/testchipip/src/main/resources/dramsim2_ini \
  +max-cycles=100000000 +loadmem=$D/mlkem768.riscv +permissive-off $D/mlkem768.riscv > $L 2>&1
echo "exit $? after $(( $(date +%s) - s )) s" >> $L
grep -E '^(cycles|check|result)|^exit' $L
