#!/bin/sh
# Build a Chipyard Verilator simulator.
# usage: build_sim.sh <Config> [jobs]     e.g. build_sim.sh RV32RocketHorcruxConfig 6
# Configs: RocketConfig, RocketHorcruxConfig (RV64); RV32RocketConfig, RV32RocketHorcruxConfig (RV32)
set -e
. "$(dirname "$0")/env.sh"
command -v conda >/dev/null 2>&1 || . "${CONDA_SH:-$HOME/miniforge3/etc/profile.d/conda.sh}"
cd "$CY" && . ./env.sh
make -C sims/verilator CONFIG=$1 -j${2:-6}
