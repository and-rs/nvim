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
    indent = {
      use_treesitter = true,
      enable = true,
      style = p.surface3,
      chars = { "»" },
    },
  })
end)
