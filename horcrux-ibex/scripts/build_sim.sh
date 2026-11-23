#!/bin/sh
# Build an Ibex Simple System Verilator simulator.
# usage: build_sim.sh base|horcrux small|maxperf [jobs]
#   base    : lowrisc:ibex:ibex_simple_system (patched Ibex, coprocessor port off = stock behaviour)
#   horcrux : fusesoc/simple_system_horcrux.core (same system + HORCRUX on the coprocessor port)
#   config  : ibex/ibex_configs.yaml entry
# Output: $OUT/sim_<system>_<config>/.../Vibex_simple_system
set -e
. "$(dirname "$0")/env.sh"
SYS=$1; CFG=$2; J=${3:-6}
case $SYS in
base)    CORE=lowrisc:ibex:ibex_simple_system; ROOTS="--cores-root=." ;;
horcrux) CORE=horcrux-ibex:sim:simple_system_horcrux; ROOTS="--cores-root=. --cores-root=$ROOT/fusesoc" ;;
*) echo "usage: $0 base|horcrux small|maxperf [jobs]"; exit 1 ;;
esac
"$ROOT/scripts/apply_patch.sh"
B=$OUT/sim_${SYS}_$CFG
mkdir -p "$OUT"; touch "$OUT/FUSESOC_IGNORE"
cd "$IBEX"
fusesoc $ROOTS run --target=sim --tool=verilator --setup --build-root=$B $CORE $(util/ibex_config.py $CFG fusesoc_opts)
W=$(dirname $(ls $B/*/sim-verilator/Makefile))
# newer Verilator versions make UNOPTFLAT fatal on Ibex (same flag as ibex-pqc/tests)
grep -q Wno-UNOPTFLAT $W/config.mk || echo 'VERILATOR_OPTIONS += -Wno-UNOPTFLAT' >> $W/config.mk
make -C $W -j$J
echo "built $W/Vibex_simple_system"
