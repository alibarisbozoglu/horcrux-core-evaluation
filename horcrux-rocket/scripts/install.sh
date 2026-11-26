#!/bin/sh
# Hook HORCRUX into Chipyard for Rocket (idempotent):
#  1. horcrux-boom/scripts/install.sh: the shared RoCC generator -> $CY/generators/horcrux, build.sbt patch
#  2. generator/chipyard/HorcruxRocketConfigs.scala -> $CY/generators/horcrux/chipyard (Chipyard compiles
#     generators/<name>/chipyard/*.scala into its config package)
# Rocket, rocket-chip and the rest of Chipyard are not touched.
set -e
. "$(dirname "$0")/env.sh"
CY="$CY" "$BOOM/scripts/install.sh"
G=$CY/generators/horcrux
cp "$ROOT"/generator/chipyard/*.scala "$G/chipyard/"
git -C "$G" add -A
git -C "$G" diff --cached --quiet ||
  git -C "$G" -c user.name=local -c user.email=local@localhost commit -qm "Rocket configs (copied from horcrux-rocket)"
echo "Rocket configs installed: RocketHorcruxConfig, RV32RocketHorcruxConfig"
