#!/bin/sh
# Hook the HORCRUX RoCC generator into Chipyard (idempotent).
#  1. generator/ -> $CY/generators/horcrux. Chipyard only picks up optional generators that have a .git,
#     so the copy gets its own small local git repo (nothing is pushed anywhere).
#  2. horcrux_rocc.sv = unchanged HORCRUX RTL + HorcruxRoCCAdapter.sv (gen_rtl.sh)
#  3. patches/chipyard-build-sbt.patch: registers "horcrux" in build.sbt like the other optional generators.
# BOOM, rocket-chip and the rest of Chipyard are not touched.
set -e
. "$(dirname "$0")/env.sh"
[ -f "$CY/build.sbt" ] || { echo "no Chipyard at $CY (run scripts/setup_chipyard.sh or set CY in local.env)"; exit 1; }
G=$CY/generators/horcrux
mkdir -p $G
cp -r $ROOT/generator/. $G/
"$ROOT/scripts/gen_rtl.sh" $G/src/main/resources/vsrc/horcrux_rocc.sv
printf 'target/\n' > $G/.gitignore
git -C $G init -q 2>/dev/null
git -C $G add -A
git -C $G diff --cached --quiet 2>/dev/null && git -C $G rev-parse -q HEAD >/dev/null ||
  git -C $G -c user.name=local -c user.email=local@localhost commit -qm "HORCRUX RoCC generator (copied from horcrux-boom)"
P=$ROOT/patches/chipyard-build-sbt.patch
if git -C "$CY" apply --reverse --check "$P" 2>/dev/null; then echo "build.sbt already patched"
else git -C "$CY" apply "$P" && echo "build.sbt patched"; fi
