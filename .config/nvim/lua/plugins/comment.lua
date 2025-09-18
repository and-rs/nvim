MiniDeps.later(function()
  MiniDeps.add({ source = "numToStr/Comment.nvim" })
  MiniDeps.add({ source = "JoosepAlviste/nvim-ts-context-commentstring" })

  vim.g.skip_ts_context_commentstring_module = true

  require("ts_context_commentstring").setup({
    enable_autocmd = false,
    padding = true,
    mappings = {
      basic = true,
      extra = false,
    },
  })

  require("ts_context_commentstring").setup({
    enable_autocmd = false,
  })

  require("Comment").setup({
    pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
  })
end)
