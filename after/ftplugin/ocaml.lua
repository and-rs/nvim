local theme = require("config.theme")
if not theme.sourced then
  return
end

local color = require("config.coloring")
color.set(
  "@variable.parameter.ocaml",
  { underline = true, sp = color.darken_hex(theme.palette.blue, 0.6) }
)
