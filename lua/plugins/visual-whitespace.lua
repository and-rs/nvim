MiniDeps.later(function()
  MiniDeps.add({ source = "mcauley-penney/visual-whitespace.nvim" })
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = vim.api.nvim_create_augroup("load-visual-whitespace", { clear = true }),
    pattern = "*",
    callback = function()
      require("visual-whitespace").setup({
        list_chars = {
          space = "·",
          tab = "»",
          nbsp = "␣",
          lead = "‹",
          trail = "›",
        },
        fileformat_chars = {
          unix = "¬",
          mac = "¬",
          dos = "¬",
        },
      })
    end,
  })
end)
