return {
  "stevearc/quicker.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("quicker").setup()
  end,
}
