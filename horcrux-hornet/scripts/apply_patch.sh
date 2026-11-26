#!/bin/sh
# Apply patches/hornet-xif.patch (the coprocessor port) to the hornet submodule. Idempotent.
set -e
. "$(dirname "$0")/env.sh"
P=$ROOT/patches/hornet-xif.patch
if git -C "$HORNET" apply --reverse --check "$P" 2>/dev/null; then echo "hornet already patched"
else git -C "$HORNET" apply "$P" && echo "hornet patched"; fi
