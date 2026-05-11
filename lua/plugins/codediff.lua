local function load()
  vim.pack.add({
    "https://github.com/MunifTanjim/nui.nvim",
    { src = "https://github.com/esmuellert/codediff.nvim", version = "v2.43.15" },
  })

  require("codediff").setup({
    cmd = "CodeDiff"
  })

  if vim.o.background == "light" then
    require("codediff").setup({
      highlights = {
        line_delete = "#ffcccc",
        char_delete = "#ffaaaa",
        line_insert = "#c0e9da",
        char_insert = "#a3dcc1",
      },
    })
  end

  vim.keymap.set("n", "<leader>gd", "<cmd>CodeDiff file HEAD<CR>", { desc = "Show Diff" })
end

vim.schedule(function()
  load()
end)
