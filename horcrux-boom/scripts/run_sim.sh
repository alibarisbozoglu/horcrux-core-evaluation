#!/bin/sh
# Run an ML-KEM-768 build on a Chipyard Verilator simulator (tile + L2 + DRAMSim2, program loaded with +loadmem).
# usage: run_sim.sh <Config> <build>     e.g. run_sim.sh SmallBoomV3Config baseline
# log: $OUT/<build>/<Config>.log
# Note: every Chipyard HTIF run here ends with "*** FAILED *** (tohost = 5)" / exit 255 after the program has
# printed its result; the "result PASS|FAIL" line is what counts.
. "$(dirname "$0")/env.sh"
CFG=$1; BLD=$2
D=$OUT/$BLD; L=$D/$CFG.log
s=$(date +%s)
$CY/sims/verilator/simulator-chipyard.harness-$CFG +permissive +dramsim \
  +dramsim_ini_dir=$CY/generators/testchipip/src/main/resources/dramsim2_ini \
  +max-cycles=100000000 +loadmem=$D/mlkem768.riscv +permissive-off $D/mlkem768.riscv > $L 2>&1
echo "exit $? after $(( $(date +%s) - s )) s" >> $L
grep -E '^(cycles|check|result)|^exit' $L
