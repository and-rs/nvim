local colors = require("config.coloring")

vim.api.nvim_set_hl(
  0,
  "@variable.parameter.ocaml",
  { underline = true, sp = colors.darken_hex(colors.get("NvimBlue", "fg"), 0.6) }
)
