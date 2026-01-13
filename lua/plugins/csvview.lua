MiniDeps.later(function()
  MiniDeps.add({ source = "hat0uma/csvview.nvim" })
  require("csvview").setup({
    parser = { comments = { "#", "//" } },
    view = {
      header_lnum = true,
      sticky_header = {
        --- @type boolean
        enabled = true,
        --- @type string|false
        separator = false,
      },
    },
  })
end)
