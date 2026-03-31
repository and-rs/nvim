vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })
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

require("nvim-treesitter").setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

local languages = {
  "ocaml",
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
}

vim.schedule(function()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = languages,
    callback = function()
      vim.treesitter.start()
    end,
  })
end)

require("nvim-treesitter").install(languages)
