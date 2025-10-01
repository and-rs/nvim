MiniDeps.later(function()
  MiniDeps.add({
    source = "neovim/nvim-lspconfig",
    dependencies = {
      "saghen/blink.cmp",
      "j-hui/fidget.nvim",
    },
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp", { clear = true }),

    callback = function(event)
      local map = function(keys, func, desc)
        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
      end

      map("K", function()
        vim.lsp.buf.hover({ border = "rounded" })
      end, "Hover LSP info")
      map("<leader>rn", vim.lsp.buf.rename, "Smart rename")

      -- Diagnostics
      map("<leader>d", function()
        vim.diagnostic.open_float({ border = "rounded" })
      end, "Show line diagnostics")

      map("[d", function()
        vim.diagnostic.jump({ float = { border = "rounded" }, count = -1 })
      end, "Go to previous diagnostic")

      map("]d", function()
        vim.diagnostic.jump({ float = { border = "rounded" }, count = -1 })
      end, "Go to next diagnostic")
    end,
  })

  vim.diagnostic.config({
    virtual_text = {
      enabled = true,
      prefix = function(diagnostic)
        if diagnostic.severity == vim.diagnostic.severity.ERROR then
          return "🭰× "
        elseif diagnostic.severity == vim.diagnostic.severity.WARN then
          return "🭰▲ "
        else
          return "🭰• "
        end
      end,
      suffix = "🭵",
    },
    underline = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = " ×",
        [vim.diagnostic.severity.WARN] = " ▲",
        [vim.diagnostic.severity.HINT] = " •",
        [vim.diagnostic.severity.INFO] = " •",
      },
    },
  })

  vim.filetype.add({
    extension = {
      env = "env",
    },
    filename = {
      [".env"] = "env",
    },
    pattern = {
      ["%.env%.[%w_.-]+"] = "env",
    },
  })

  vim.lsp.enable("gopls")
  vim.lsp.enable("nil_ls")
  vim.lsp.enable("bashls")
  vim.lsp.enable("zls")
  vim.lsp.config.zls = {
    settings = {
      semantic_tokens = "none",
    },
  }

  -- vim.lsp.enable("ty")
  -- vim.lsp.enable("zuban")
  -- vim.lsp.enable("pyrefly")
  vim.lsp.enable({ "ruff", "basedpyright" })
  vim.lsp.config.basedpyright = {
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
  }

  vim.lsp.enable({ "jsonls", "eslint", "biome", "html", "cssls" })

  vim.lsp.config.html = {
    filetypes = { "jinja", "htmldjango" },
  }
  vim.lsp.config.cssls = {
    settings = {
      css = {
        validate = true,
        lint = {
          unknownAtRules = "ignore",
        },
      },
    },
  }

  vim.lsp.enable("glsl_analyzer")

  vim.lsp.enable("tailwindcss")
  vim.lsp.config("tailwindcss", require("lsp.tailwind"))

  vim.lsp.enable("lua_ls")
  vim.lsp.config.lua_ls = {
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
  }
end)
