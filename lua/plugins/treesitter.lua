vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })

vim.treesitter.language.register("bash", "env")
vim.treesitter.language.register("tsx", { "typescriptreact", "javascriptreact" })

vim.filetype.add({
  extension = {
    mdx = "markdown",
    qml = "qmljs",
    jinja = "jinja",
    j2 = "jinja",
    azcli = "bash",
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
  highlight = {
    enable = true,
  },
})

local parser_languages = {
  "bicep",
  "rust",
  "ocaml",
  "qmljs",
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

local filetypes = vim.list_extend(vim.deepcopy(parser_languages), {
  "typescriptreact",
  "javascriptreact",
})

local M = {
  filetypes = filetypes,
}

function M.has_parser(filetype)
  return pcall(vim.treesitter.language.get_lang, filetype)
end

function M.has_highlighting(buf)
  return vim.treesitter.highlighter.active[buf] ~= nil
end

vim.schedule(function()
  vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    pattern = filetypes,
    callback = function()
      vim.treesitter.start()
    end,
  })
end)

require("nvim-treesitter").install(parser_languages)

return M