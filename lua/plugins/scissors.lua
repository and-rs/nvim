vim.pack.add({
  { src = "https://github.com/chrisgrieser/nvim-scissors" },
  "https://github.com/ibhagwan/fzf-lua",
})

require("scissors").setup({
  snippetDir = "$HOME/.config/nvim/snippets/",
  editSnippetPopup = {
    height = 0.4,
    width = 0.5,
    border = "rounded",
  },
})
