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

    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.tsx,*.jsx,*.ts,*.js",
      callback = function()
        -- Ensure the client is actually idle before sending commands
        if not vim.tbl_isempty(client.progress.pending) then
          return
        end

        local bnr = vim.api.nvim_get_current_buf()
        local filename = vim.api.nvim_buf_get_name(bnr)
        local ft = vim.bo[bnr].filetype
        local prefix = ft:find("javascript") and "javascript" or "typescript"

        local function execute_cleanly(command)
          local view = vim.fn.winsaveview()
          local tick = vim.api.nvim_buf_get_changedtick(bnr)
          local lines_before = vim.api.nvim_buf_get_lines(bnr, 0, -1, false)

          vim.lsp.buf_request_sync(bnr, "workspace/executeCommand", {
            command = command,
            arguments = { filename },
          }, 2000)

          local lines_after = vim.api.nvim_buf_get_lines(bnr, 0, -1, false)
          if
            tick ~= vim.api.nvim_buf_get_changedtick(bnr)
            and vim.deep_equal(lines_before, lines_after)
          then
            vim.cmd("silent! undo")
          end
          vim.fn.winrestview(view)
        end

        execute_cleanly(prefix .. ".removeUnusedImports")
        execute_cleanly(prefix .. ".sortImports")
        require("conform").format({ async = false })
      end,
    })
  end,
})
