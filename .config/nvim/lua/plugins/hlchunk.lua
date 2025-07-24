return {
  "shellRaining/hlchunk.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
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
        style = Get_hl_hex("Comment", "fg"),
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
  end,
}
