local color = require("config.coloring")

color.set(
  "@variable.parameter.ocaml",
  { underline = true, sp = color.darken_hex(color.get("NvimBlue", "fg"), 0.6) }
)
