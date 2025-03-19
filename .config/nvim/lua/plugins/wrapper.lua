return {
  "andrewferrier/wrapping.nvim",
  config = function()
    require("wrapping").setup({
      set_nvim_opt_defaults = false,
    })
  end,
}
