return {
  "chrisgrieser/nvim-scissors",
  event = { "BufNewFile", "BufReadPre" },
  dependencies = "ibhagwan/fzf-lua",
  opts = {
    snippetDir = "$HOME/.config/nvim/snippets/",
    editSnippetPopup = {
      height = 0.4,
      width = 0.5,
      border = "single",
    },
  },
}
