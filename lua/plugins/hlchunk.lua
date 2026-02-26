MiniDeps.later(function()
  MiniDeps.add({ source = "shellRaining/hlchunk.nvim" })
  local coloring = require("config.coloring")
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
      style = coloring.get("NvimGrey", "fg"),
      duration = 0,
      delay = 0,
    },
    blank = {
      enable = false,
      chars = {
        "▏",
      },
    },
  })
end)
