#!/bin/sh
# Fresh Chipyard 1.15.0 in ./chipyard (the pinned submodule horcrux-boom/chipyard) + its toolchain. Large (tens of GB) and slow.
# Skip this if you already have Chipyard 1.15.0: put CY=/path/to/chipyard in ./local.env instead.
# usage: setup_chipyard.sh [--sysroot-2.39] [build-setup.sh args...]   (default args: riscv-tools)
#   --sysroot-2.39  apply patches/chipyard-sysroot-2.39.patch first (needed on hosts where the stock
#                   sysroot_linux-64=2.34 conda env does not build, e.g. our Fedora machine)
set -e
. "$(dirname "$0")/env.sh"
git -C "$ROOT/.." submodule update --init horcrux-boom/chipyard
if [ "$1" = "--sysroot-2.39" ]; then shift; git -C "$CY" apply "$ROOT/patches/chipyard-sysroot-2.39.patch"; fi
[ $# -eq 0 ] && set -- riscv-tools
cd "$CY" && ./build-setup.sh "$@"
