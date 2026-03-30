vim.pack.add({
  "https://github.com/MunifTanjim/nui.nvim",
  { src = "https://github.com/esmuellert/codediff.nvim", version = "next" },
})
vim.pack.add({ "https://github.com/MunifTanjim/nui.nvim" })

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
