return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  config = function()
    require("tiny-inline-diagnostic").setup({
      signs = {
        left = "",
        right = "",
        diag = " >",
        arrow = "",
        up_arrow = "^",
        vertical = " │",
        vertical_end = " └",
      },
      hi = {
        background = "None",
        mixing_color = "None",
      },
      options = {
        multiple_diag_under_cursor = true,
        overflow = {
          mode = "none",
        },
        break_line = {
          enabled = false,
        },
      },
    })
    vim.diagnostic.config({ virtual_text = false })
  end,
}
