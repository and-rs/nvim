local function load()
  vim.pack.add({
    "https://github.com/MunifTanjim/nui.nvim",
    { src = "https://github.com/esmuellert/codediff.nvim" },
  })

  require("codediff").setup({
    highlights = {
      char_brightness = 1.2,
    },
    diff = {
      original_position = "right",
    },
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
