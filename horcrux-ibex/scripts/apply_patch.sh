#!/bin/sh
# Apply patches/ibex-xif.patch (the coprocessor port) to the ibex submodule. Idempotent.
set -e
. "$(dirname "$0")/env.sh"
P=$ROOT/patches/ibex-xif.patch
if git -C "$IBEX" apply --reverse --check "$P" 2>/dev/null; then echo "ibex already patched"
else git -C "$IBEX" apply "$P" && echo "ibex patched"; fi
