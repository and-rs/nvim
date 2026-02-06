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

-- The ultimate import handling
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("VtslsOnSave", { clear = false }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not (client and client.name == "vtsls") then
      return
    end

    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = args.buf,
      callback = function(opts)
        if not vim.tbl_isempty(client.progress.pending) then
          return
        end
        local prefix = (
          vim.bo[opts.buf].filetype:find("javascript") and "javascript" or "typescript"
        ) .. "."
        local fname = vim.api.nvim_buf_get_name(opts.buf)
        for _, action in ipairs({ "removeUnusedImports", "sortImports" }) do
          local view = vim.fn.winsaveview()
          local lines = vim.api.nvim_buf_get_lines(opts.buf, 0, -1, false)
          local tick = vim.api.nvim_buf_get_changedtick(opts.buf)

          vim.lsp.buf_request_sync(opts.buf, "workspace/executeCommand", {
            command = prefix .. action,
            arguments = { fname },
          }, 2000)

          if
            tick ~= vim.api.nvim_buf_get_changedtick(opts.buf)
            and vim.deep_equal(lines, vim.api.nvim_buf_get_lines(opts.buf, 0, -1, false))
          then
            vim.cmd("silent! undo")
          end
          vim.fn.winrestview(view)
        end
      end,
    })
  end,
})
