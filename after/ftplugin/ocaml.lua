local color = require("config.coloring")

color.set(
  "@variable.parameter.ocaml",
  { underline = true, sp = colors.darken_hex(colors.get("NvimBlue", "fg"), 0.6) }
)
