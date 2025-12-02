MiniDeps.later(function()
  MiniDeps.add({ source = "esmuellert/vscode-diff.nvim", dependencies = "MunifTanjim/nui.nvim" })
  MiniDeps.add({ source = "MunifTanjim/nui.nvim" })

  vim.keymap.set("n", "<leader>gd", "<cmd>CodeDiff file HEAD<CR>", { desc = "Show Diff" })
end)
