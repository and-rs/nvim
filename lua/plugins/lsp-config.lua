MiniDeps.now(function()
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
        vim.lsp.buf.hover({
          border = "rounded",
          max_width = math.floor(vim.o.columns / 2) + 8,
        })
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
          return "▏× "
        elseif diagnostic.severity == vim.diagnostic.severity.WARN then
          return "▏▲ "
        else
          return "▏• "
        end
      end,
      suffix = "▕",
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
    -- "unocss",
    "tailwindcss",

    -- py
    "ty",
    "ruff",
    -- "basedpyright",

    -- shells
    "fish_lsp",
    "nushell",
    "bashls",

    "zls",
    "gopls",
    "buf_ls",
    "yamlls",
    "nil_ls",
    "lua_ls",
    "ast_grep",
    "glsl_analyzer",
  }

  vim.lsp.enable(enabled_lsps)

  vim.lsp.config.biome = {
    capabilities = { general = { positionEncodings = { "utf-8" } } },
    cmd = function(dispatchers)
      local cmd = "biome"
      return vim.lsp.rpc.start({ cmd, "lsp-proxy" }, dispatchers)
    end,
  }

  vim.lsp.config("tailwindcss", require("lsp.tailwind"))
  vim.lsp.config("unocss", {
    cmd = { "bunx", "--bun", "-p", "unocss-language-server", "unocss-language-server", "--stdio" },
  })

  vim.lsp.config.nil_ls = {
    settings = { ["nil"] = { nix = { flake = { autoArchive = true } } } },
  }

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

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "FileType" }, {
  group = vim.api.nvim_create_augroup("ast_grep_attach", { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    if vim.bo[buf].buftype ~= "" then
      return
    end
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
      return
    end
    local client = vim.lsp.get_clients({ name = "ast_grep" })[1]
    if not client then
      return
    end
    if client.attached_buffers[buf] then
      return
    end
    local util = require("lspconfig.util")
    local root = util.root_pattern("sgconfig.yaml", "sgconfig.yml")(name)
    if not root then
      return
    end
    if client.root_dir ~= root then
      return
    end
    vim.lsp.buf_attach_client(buf, client.id)
  end,
})
