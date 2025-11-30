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

  local enabled_lsps = {
    -- js
    "html",
    "biome",
    "cssls",
    "jsonls",
    "eslint",
    "tailwindcss",
    -- py
    "ruff",
    "basedpyright",
    -- random
    "zls",
    "gopls",
    "yamlls",
    "qmlls",
    "nil_ls",
    "bashls",
    "lua_ls",
    "glsl_analyzer",
  }

  vim.lsp.enable(enabled_lsps)
  vim.lsp.config("tailwindcss", require("lsp.tailwind"))

  vim.lsp.config.zls = {
    settings = {
      semantic_tokens = "none",
    },
  }

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

  vim.lsp.config.jsonls = {
    init_options = {
      provideFormatter = false,
    },
  }

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

  vim.lsp.config.lua_ls = {
    settings = {
      Lua = {
        workspace = {
          ignoreSubmodules = true,
          library = { vim.env.VIMRUNTIME },
        },
      },
    },
  }
end)
