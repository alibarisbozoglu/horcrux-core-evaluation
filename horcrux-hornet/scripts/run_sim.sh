#!/bin/sh
# Run the ML-KEM-768 test on a simulator from build_sim.sh.
# usage: scripts/run_sim.sh base|horcrux <isa> baseline|optimized   -> log: $OUT/run/<sys>_<isa>_<build>.log
set -e
. "$(dirname "$0")/env.sh"
SYS=$1; ISA=$2; V=$3
S=$OUT/sim_${SYS}_$ISA/Vsoc_tb; P=$OUT/sw/$V/mlkem768
[ -x "$S" ] || { echo "no simulator $S (scripts/build_sim.sh $SYS $ISA)"; exit 1; }
[ -f "$P.imem.hex" ] || { echo "no program $P (sw/build.sh $V)"; exit 1; }
mkdir -p "$OUT/run"; L=$OUT/run/${SYS}_${ISA}_$V.log
"$S" +imem=$P.imem.hex +dmem=$P.dmem.hex +timeout=200000000 | grep -v "^- " | tee "$L"
grep -q "^PASS" "$L"
