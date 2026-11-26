package chipyard

import org.chipsalliance.cde.config.Config

// Rocket with the HORCRUX PQC coprocessor on RoCC custom0/custom1 (RoCC module: horcrux-boom/generator).
// References without HORCRUX: RocketConfig / RV32RocketConfig (RocketConfigs.scala), identical otherwise.
class RocketHorcruxConfig extends Config(
  new horcrux.WithHorcruxRoCC ++
  new RocketConfig)

class RV32RocketHorcruxConfig extends Config(
  new horcrux.WithHorcruxRoCC ++
  new RV32RocketConfig)
