local function load()
  vim.pack.add({ "https://github.com/hat0uma/csvview.nvim" })
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
end

vim.api.nvim_create_autocmd("FileType", {
  group = Deferred_group,
  callback = load,
  pattern = "csv",
})
