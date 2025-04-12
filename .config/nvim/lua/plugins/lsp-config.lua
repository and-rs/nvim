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
      group = vim.api.nvim_create_augroup("lsp", { clear = true }),

      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
        end

        map("K", function()
          vim.lsp.buf.hover({ border = "single" })
        end, "Hover LSP info")
        map("<leader>rn", vim.lsp.buf.rename, "Smart rename")

        -- Diagnostics
        map("<leader>d", function()
          vim.diagnostic.open_float({ border = "single" })
        end, "Show line diagnostics")
        map("[d", vim.diagnostic.goto_prev, "Go to previous diagnostic")
        map("]d", vim.diagnostic.goto_next, "Go to next diagnostic")
      end,
    })

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = { ".env", ".env.*" },
      group = "lsp",
      callback = function()
        vim.diagnostic.enable(false)
      end,
    })

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = ".env.example",
      group = "lsp",
      callback = function()
        vim.cmd("setfiletype sh")
      end,
    })

    vim.diagnostic.config({
      virtual_text = {
        enabled = true,
        spacing = 0,
        -- TODO = implement fucntion for severity
        prefix = " •",
        suffix = " |",
        hl_mode = "blend",
        virt_text_pos = "eol",
      },
      underline = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "×",
          [vim.diagnostic.severity.WARN] = "•",
          [vim.diagnostic.severity.HINT] = "•",
          [vim.diagnostic.severity.INFO] = "•",
        },
      },
    })

    local servers = {
      -- zig, go and nix
      zls = {
        settings = {
          semantic_tokens = "none",
        },
      },
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
      -- sqls = {},

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
      },
    }

    for server, config in pairs(servers) do
      config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
      require("lspconfig")[server].setup(config)
    end
  end,
}
