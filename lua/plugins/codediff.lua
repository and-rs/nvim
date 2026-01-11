MiniDeps.now(function()
  MiniDeps.add({
    checkout = "next",
    source = "esmuellert/codediff.nvim",
    dependencies = "MunifTanjim/nui.nvim",
  })
  MiniDeps.add({ source = "MunifTanjim/nui.nvim" })

  vim.keymap.set("n", "<leader>gd", "<cmd>CodeDiff file HEAD<CR>", { desc = "Show Diff" })
end)
