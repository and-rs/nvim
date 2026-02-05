MiniDeps.later(function()
  MiniDeps.add({
    source = "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  })
  require("typescript-tools").setup({})
end)
