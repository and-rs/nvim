MiniDeps.later(function()
  MiniDeps.add({ source = "stevearc/conform.nvim" })

  local conform = require("conform")
  local prose_wrap = true

  conform.formatters = {
    ["biome-organize-imports"] = {
      command = "biome",
    },
    biome = {
      command = "biome",
    },
    qmlformat = {
      append_args = { "-w 2" },
    },
    sleek = {
      append_args = { "--indent-spaces=2", "--lines-between-queries=1" },
    },
    deno_fmt = {
      append_args = { "--prose-wrap=always" },
    },
    deno_fmt_md = {
      inherit = "deno_fmt",
      append_args = function()
        return { "--prose-wrap=" .. (prose_wrap and "always" or "never") }
      end,
    },
  }

  conform.setup({
    formatters_by_ft = {
      javascriptreact = { "biome", "rustywind" },
      typescriptreact = { "biome", "rustywind" },
      javascript = { "biome", "rustywind" },
      typescript = { "biome", "rustywind" },
      svelte = { "biome", "rustywind" },

      graphql = { "biome" },
      css = { "biome" },

      html = { "deno_fmt", "rustywind" },
      jsonc = { "deno_fmt" },
      json = { "deno_fmt" },

      -- nu = { "nufmt" },
      sh = { "beautysh" },
      fish = { "fish_indent" },

      python = { "ruff_format", "ruff_organize_imports" },
      htmldjango = { "djlint", "rustywind" },
      jinja = { "djlint", "rustywind" },

      markdown = { "deno_fmt_md" },
      qml = { "qmlformat" },
      yaml = { "yamlfmt" },
      kdl = { "kdlfmt" },
      lua = { "stylua" },
      nix = { "nixfmt" },
      sql = { "sleek" },
    },
    format_on_save = {
      lsp_fallback = true,
      timeout_ms = 2000,
      async = false,
    },
  })

  vim.keymap.set("n", "<leader>mp", function()
    conform.format({ lsp_fallback = true, async = false, timeout_ms = 2000 })
  end, { desc = "Make Pretty" })

  vim.keymap.set("n", "<leader>mw", function()
    prose_wrap = not prose_wrap
    vim.notify("Prose wrap: " .. (prose_wrap and "always" or "never"))
  end, { desc = "Toggle markdown prose wrap" })
end)
