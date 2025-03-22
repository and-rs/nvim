return {
  -- dir = "~/dev/statuscolumn.nvim",
  "JuanBaut/statuscolumn.nvim",
  -- enabled = false,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("statuscolumn").setup({
      enable_border = true,
      gradient_hl = "Statement",
    })
  end,
}
