vim.pack.add({ "https://github.com/kylechui/nvim-surround" })

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
