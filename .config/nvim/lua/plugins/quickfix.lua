return {
  "stevearc/quicker.nvim",
  config = function()
    require("quicker").setup({
      borders = {
        vert = " ╎ ",
        -- Strong headers separate results from different files
        strong_header = "━",
        strong_cross = "╋",
        strong_end = "┫",
        -- Soft headers separate results within the same file
        soft_header = "╌",
        soft_cross = "╂",
        soft_end = "┨",
      },
    })

    vim.api.nvim_set_hl(0, "QuickFixHeaderHard", { link = "Conceal" })
    vim.api.nvim_set_hl(0, "QuickFixLineNr", { link = "@variable" })
  end,
}
