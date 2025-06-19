return {
  "JuanBaut/statuscolumn.nvim",
  -- dir = "~/vault/dev/statuscolumn.nvim",
  config = function()
    require("statuscolumn").setup({
      enable_border = true,
      gradient_hl = "PreProc",
    })
  end,
}
