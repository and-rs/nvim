MiniDeps.later(function()
  MiniDeps.add({ source = "kylechui/nvim-surround" })

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
end)
