return {
  --dir = "~/dev/statuscolumn.nvim",
  "JuanBaut/statuscolumn.nvim",
  event = { "BufReadPre", "BufNewFile" },
  enabled = false,
  lazy = false,
  config = function()
    require("statuscolumn").setup({
      enable_border = false,
      gradient_hl = "Statement",
    })
  end,
}
