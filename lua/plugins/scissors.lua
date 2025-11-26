MiniDeps.later(function()
  MiniDeps.add({ source = "chrisgrieser/nvim-scissors", dependencies = { "ibhagwan/fzf-lua" } })

  require("scissors").setup({
    snippetDir = "$HOME/.config/nvim/snippets/",
    editSnippetPopup = {
      height = 0.4,
      width = 0.5,
      border = "rounded",
    },
  })
end)
