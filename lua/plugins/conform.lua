MiniDeps.later(function()
  MiniDeps.add({ source = "stevearc/conform.nvim" })

  local conform = require("conform")

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

      markdown = { "deno_fmt" },
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
    conform.format({
      lsp_fallback = true,
      async = false,
      timeout_ms = 2000,
    })
  end, { desc = "Make Pretty" })
end)
