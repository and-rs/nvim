local function load()
  vim.pack.add({ "https://github.com/windwp/nvim-ts-autotag" })

  require("nvim-ts-autotag").setup({
    aliases = {
      ["jinja"] = "html",
    },
    opts = {
      enable_close = true, -- Auto close tags
      enable_rename = false, -- Auto rename pairs of tags
      enable_close_on_slash = true, -- Auto close on trailing </
    },
  })
end

vim.schedule(function()
  vim.api.nvim_create_autocmd({ "InsertEnter", "BufEnter", "BufFilePre" }, {
    group = Deferred_group,
    callback = load,
  })
end)
