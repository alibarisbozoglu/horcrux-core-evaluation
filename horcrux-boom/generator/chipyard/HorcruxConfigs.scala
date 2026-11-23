package chipyard

import org.chipsalliance.cde.config.Config

// SmallBOOM with the HORCRUX PQC coprocessor on RoCC custom0/custom1.
// Reference without HORCRUX: SmallBoomV3Config (BoomConfigs.scala), identical otherwise.
class SmallBoomV3HorcruxConfig extends Config(
  new horcrux.WithHorcruxRoCC ++
  new SmallBoomV3Config)
