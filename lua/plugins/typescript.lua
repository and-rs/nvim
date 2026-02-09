MiniDeps.later(function()
  MiniDeps.add({ source = "yioneko/nvim-vtsls" })
  require("lspconfig.configs").vtsls = require("vtsls").lspconfig

  require("lspconfig").vtsls.setup({
    settings = {
      vtsls = {
        typescript = {
          format = {
            convertTabsToSpaces = true,
            baseIndentSize = 2,
            indentSize = 2,
            -- 0: None, 1: Block, 2: Smart
            indentStyle = 0,
          },
        },
      },
    },
  })
end)

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("VtslsOnSave", { clear = false }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not (client and client.name == "vtsls") then
      return
    end
    if not vim.tbl_isempty(client.progress.pending) then
      return
    end

    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = args.buf, desc = desc })
    end

    map("<leader>lu", function()
      vim.cmd("VtsExec remove_unused_imports")
    end, "TS Remove Unused Imports")
    map("<leader>lo", function()
      vim.cmd("VtsExec organize_imports")
    end, "TS Organize Imports")
  end,
})
