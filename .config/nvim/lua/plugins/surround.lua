return {
  "kylechui/nvim-surround",
  version = "*",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("nvim-surround").setup({
      surrounds = {
        F = {
          add = { "<>", "</>" },
          find = "<>.-</>",
          delete = "^(<>)().-(</>)()$",
          change = {
            target = "^(<>)().-(</>)()$",
            replacement = { "<>", "</>" },
          },
        },
      },
    })
  end,
}
