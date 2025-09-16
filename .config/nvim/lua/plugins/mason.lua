return {
  "williamboman/mason.nvim",
  event = { "BufReadPre", "BufNewFile" },
  cmd = "Mason",
  config = function()
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
  end,
}
