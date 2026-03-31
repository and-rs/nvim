local function load()
  vim.pack.add({ "https://github.com/numToStr/Comment.nvim" })
  vim.pack.add({ "https://github.com/JoosepAlviste/nvim-ts-context-commentstring" })

  vim.g.skip_ts_context_commentstring_module = true

  require("ts_context_commentstring").setup({
    enable_autocmd = false,
    padding = true,
    mappings = {
      basic = true,
      extra = false,
    },
  })

  require("Comment").setup({
    pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
  })
end

vim.schedule(function()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = Deferred_group,
    callback = load,
  })
end)
