local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "dagger.plugins" },
  { import = "dagger.plugins.ui" },
  { import = "dagger.plugins.lsp" },
  { import = "dagger.plugins.unused" },
  { import = "dagger.plugins.colors" },
}, {
  ui = {
    border = "single",
    size = {
      width = 0.95,
      height = 0.9,
    },
  },
})

-- Enabling commentstring
vim.g.skip_ts_context_commentstring_module = true

require("Comment").setup({
  pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
})

require("ts_context_commentstring").setup({
  enable_autocmd = false,
})
