MiniDeps.later(function()
  MiniDeps.add({
    source = "nvim-treesitter/nvim-treesitter",
    hooks = {
      post_checkout = function()
        vim.cmd("TSUpdate")
      end,
    },
  })

  local treesitter = require("nvim-treesitter.configs")
  vim.treesitter.language.register("bash", "env")

  vim.filetype.add({
    extension = {
      jinja = "jinja",
      env = "env",
    },
    filename = {
      [".env"] = "env",
    },
    pattern = {
      ["%.env%.[%w_.-]+"] = "env",
    },
  })

  treesitter.setup({
    highlight = {
      enable = true,
    },
    indent = { enable = true },
    ensure_installed = {
      "jsonc",
      "json",
      "javascript",
      "typescript",
      "tsx",
      "html",
      "css",
      "svelte",

      "gitignore",
      "query",
      "hurl",

      "markdown",
      "markdown_inline",

      "dockerfile",
      "yaml",
      "toml",
      "kdl",

      "nu",
      "bash",

      "sql",
      "jinja",
      "python",

      "vim",
      "vimdoc",

      "luadoc",
      "proto",
      "nix",
      "lua",
      "zig",
      "go",
    },
  })
end)

MiniDeps.later(function()
  local color = require("config.coloring")
  color.set("TreesitterContext", {
    bg = color.adjust_hex(color.get("Visual", "bg"), 0.8),
  })
end)
