MiniDeps.later(function()
  MiniDeps.add({
    source = "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  })

  require("typescript-tools").setup({})
  vim.api.nvim_create_autocmd("LspAttach", {
    pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
    callback = function()
      vim.keymap.set("n", "<leader>li", function()
        vim.notify("Organizing imports...")
        vim.cmd("TSToolsOrganizeImports")
      end, { desc = "Organize imports" })
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
    callback = function()
      vim.keymap.set("n", "<leader>la", function()
        vim.notify("Adding missing imports...")
        vim.cmd("TSToolsAddMissingImports")
      end, { desc = "Add missing imports" })
    end,
  })
end)
