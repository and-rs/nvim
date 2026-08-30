vim.schedule(function()
  vim.pack.add({ "https://github.com/shellRaining/hlchunk.nvim" })

  local colors = require("config.coloring")
  local theme = require("config.theme")
  local p = theme.palette
  require("hlchunk").setup({
    chunk = {
      enable = true,
      chars = {
        horizontal_line = "─",
        vertical_line = "│",
        left_top = "┌",
        left_bottom = "└",
        right_arrow = "─",
      },
      style = theme.sourced and p.yellow or nil,
      duration = 0,
      delay = 0,
    },
    blank = {
      enable = true,
      style = theme.sourced and colors.adjust_hex(p.surface3, 0.6) or nil,
      chars = { "»" },
    },
  })
end)
