return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "saghen/blink.cmp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "j-hui/fidget.nvim", opts = {} },
  },

  config = function()
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),

      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
        end

        map("<leader>rn", vim.lsp.buf.rename, "Smart rename")
        map("gd", "<cmd>lua vim.lsp.buf.definition()<CR>", "Go to Definition")

        -- Diagnostics
        map("<leader>d", vim.diagnostic.open_float, "Show line diagnostics")
        map("[d", vim.diagnostic.goto_prev, "Go to previous diagnostic")
        map("]d", vim.diagnostic.goto_next, "Go to next diagnostic")
      end,
    })

    -- Change the Diagnostic symbols in the sign column (gutter)
    local signs = { Error = "×", Warn = "•", Hint = "•", Info = "•" }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    local servers = {
      -- zig, go and nix
      zls = {},
      gopls = {},
      nil_ls = {},

      -- python
      ruff = {},
      basedpyright = {
        settings = {
          pyright = {
            disableOrganizeImports = true,
          },
          python = {
            analysis = {
              ignore = { "*" },
            },
          },
        },
      },

      -- sql
      -- postgres_lsp = {},
      sqls = {},

      -- js tooling
      biome = {},
      eslint = {},
      tailwindcss = {},

      -- html, json, css
      html = {},
      jsonls = {},
      cssls = {
        settings = {
          css = {
            validate = true,
            lint = {
              unknownAtRules = "ignore",
            },
          },
          scss = {
            validate = true,
            lint = {
              unknownAtRules = "ignore",
            },
          },
          less = {
            validate = true,
            lint = {
              unknownAtRules = "ignore",
            },
          },
        },
      },

      -- bash
      bashls = {},

      -- lua
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = "Replace",
            },
            diagnostics = {
              globals = { "vim" },
              disable = { "missing-fields" },
            },
          },
        },
        -- cmd = {...},
        -- filetypes = { ...},
        -- capabilities = {},
      },
      -- clangd = {},
      -- rust_analyzer = {},
    }

    for server, config in pairs(servers) do
      config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
      require("lspconfig")[server].setup(config)
    end

    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
      border = { "│", "", "│", "│", "│", "", "│", "│" },
    })

    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
      border = { "│", "", "│", "│", "│", "", "│", "│" },
    })

    vim.diagnostic.config({
      border = { "│", "", "│", "│", "│", "", "│", "│" },
    })
  end,
}
