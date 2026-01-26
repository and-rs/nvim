MiniDeps.now(function()
  MiniDeps.add({
    checkout = "next",
    source = "esmuellert/codediff.nvim",
    dependencies = "MunifTanjim/nui.nvim",
  })
  MiniDeps.add({ source = "MunifTanjim/nui.nvim" })

  if vim.o.background == "light" then
    require("codediff").setup({
      highlights = {
        line_delete = "#ffcccc",
        char_delete = "#ffaaaa",
        line_insert = "#c0e9da",
        char_insert = "#a3dcc1",
      },
    })
  end

  vim.keymap.set("n", "<leader>gd", "<cmd>CodeDiff file HEAD<CR>", { desc = "Show Diff" })
end)
