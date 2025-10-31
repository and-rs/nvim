MiniDeps.later(function()
  MiniDeps.add({
    source = "nvim-treesitter/nvim-treesitter",
    hooks = {
      post_checkout = function()
        vim.cmd("TSUpdate")
      end,
    },
  })

  MiniDeps.add({
    source = "nvim-treesitter/nvim-treesitter-context",
  })
  require("treesitter-context").setup({
    min_window_height = 10,
    zindex = 100,
  })

  local treesitter = require("nvim-treesitter.configs")
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

  vim.treesitter.language.register("bash", "env")

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

      "jinja",
      "python",

      "vim",
      "vimdoc",

      "luadoc",
      "nix",
      "lua",
      "zig",
      "go",
    },
  })
end)
