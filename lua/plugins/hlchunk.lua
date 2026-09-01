vim.schedule(function()
  vim.pack.add({ "https://github.com/shellRaining/hlchunk.nvim" })

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
      style = theme.sourced and p.cyan or nil,
      duration = 0,
      delay = 0,
    },
    blank = {
      enable = true,
      style = theme.sourced and p.surface3 or nil,
      chars = { "»" },
    },
  })
end)
