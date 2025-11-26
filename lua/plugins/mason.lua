MiniDeps.later(function()
  MiniDeps.add({ source = "williamboman/mason.nvim" })

  require("mason").setup({
    ui = {
      width = 0.8,
      height = 0.8,
      border = "rounded",
      icons = {
        package_installed = "¤",
        package_pending = "»",
        package_uninstalled = "×",
      },
    },
  })
end)
