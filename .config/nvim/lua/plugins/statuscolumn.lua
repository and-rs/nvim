MiniDeps.now(function()
  MiniDeps.add({ source = "and-rs/statuscolumn.nvim" })

  require("statuscolumn").setup({
    enable_border = true,
    gradient_hl = "Constant",
  })
end)
