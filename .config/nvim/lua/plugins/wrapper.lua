MiniDeps.later(function()
  MiniDeps.add({ source = "andrewferrier/wrapping.nvim" })

  require("wrapping").setup({
    set_nvim_opt_defaults = false,
  })
end)
