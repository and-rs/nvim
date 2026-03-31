vim.pack.add({ "https://github.com/shellRaining/hlchunk.nvim" })
local colors = require("config.coloring")

vim.schedule(function()
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
      style = colors.get("NvimBlue", "fg"),
      duration = 0,
      delay = 0,
    },
    blank = {
      enable = true,
      style = colors.darken_hex(colors.get("NvimGrey", "fg"), 0.7),
      chars = { "│", "" },
    },
  })
end)
