return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  --dependencies = {
  --  "nvim-treesitter/nvim-treesitter-textobjects",
  --},
  config = function()
    local treesitter = require("nvim-treesitter.configs")
    vim.treesitter.language.register("bash", "env")

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
        "python",

        "vim",
        "vimdoc",

        "luadoc",
        "lua",
        "zig",
        "go",
      },
    })
  end,
}
