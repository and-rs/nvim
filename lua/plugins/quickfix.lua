MiniDeps.later(function()
  MiniDeps.add({ source = "stevearc/quicker.nvim" })

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
  vim.api.nvim_set_hl(0, "QuickFixLineNr", { link = "Special" })
  vim.api.nvim_set_hl(0, "QuickFixLine", { link = "Visual" })
end)
