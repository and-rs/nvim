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
      append_args = { "--indent-spaces=2" },
    },
    deno_fmt = {
      append_args = { "--prose-wrap=never" },
    },
  }

  conform.setup({
    formatters_by_ft = {
      javascript = { "biome", "biome-organize-imports", "rustywind" },
      typescript = { "biome", "biome-organize-imports", "rustywind" },
      javascriptreact = { "biome", "biome-organize-imports", "rustywind" },
      typescriptreact = { "biome", "biome-organize-imports", "rustywind" },
      svelte = { "biome", "biome-organize-imports", "rustywind" },
      css = { "biome", "biome-organize-imports" },
      graphql = { "biome", "biome-organize-imports" },

      html = { "deno_fmt", "rustywind" },
      json = { "deno_fmt" },
      jsonc = { "deno_fmt" },

      zsh = { "beautysh" },
      sh = { "beautysh" },

      htmldjango = { "djlint", "rustywind" },
      jinja = { "djlint", "rustywind" },
      python = { "ruff_format", "ruff_organize_imports" },

      qml = { "qmlformat" },
      markdown = { "deno_fmt" },
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
