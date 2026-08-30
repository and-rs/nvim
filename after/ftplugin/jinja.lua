local theme = require("config.theme")
if theme.sourced then
  local p = theme.palette
  vim.api.nvim_set_hl(0, "@tag.delimiter.html", { fg = p.surface5 })
  vim.api.nvim_set_hl(0, "@operator.jinja", { fg = p.blue })
end
vim.api.nvim_set_hl(0, "@string.special.url", { link = "None" })
vim.api.nvim_set_hl(0, "@markup.heading.3.html", { bold = false })
