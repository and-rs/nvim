return {
  "williamboman/mason.nvim",
  event = { "BufReadPre", "BufNewFile" },
  cmd = "Mason",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    require("mason").setup({
      ui = {
        width = 0.95,
        height = 0.9,
        border = "single",
        icons = {
          package_installed = "¤",
          package_pending = "»",
          package_uninstalled = "×",
        },
      },
    })
  end,
}
