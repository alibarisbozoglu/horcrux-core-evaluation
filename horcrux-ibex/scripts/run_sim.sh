#!/bin/sh
# Run an ML-KEM-768 build on an Ibex Simple System simulator.
# usage: run_sim.sh base|horcrux small|maxperf baseline|optimized
# log: $OUT/run/<system>_<config>_<build>.log (the program output, ibex_simple_system.log)
. "$(dirname "$0")/env.sh"
SYS=$1; CFG=$2; BLD=$3
SIM=$(ls $OUT/sim_${SYS}_$CFG/*/sim-verilator/Vibex_simple_system)
D=$OUT/run/${SYS}_${CFG}_$BLD; L=$OUT/run/${SYS}_${CFG}_$BLD.log
mkdir -p $D && cd $D
s=$(date +%s)
$SIM --meminit=ram,$OUT/sw/$BLD/mlkem768.elf --term-after-cycles=200000000 +ibex_tracer_enable=0 \
  > sim_stdout.log 2>&1 < /dev/null
rc=$?
{ cat ibex_simple_system.log; echo; echo "exit $rc after $(( $(date +%s) - s )) s"; } > $L
grep -E '^(cycles|check|result)|^exit' $L
