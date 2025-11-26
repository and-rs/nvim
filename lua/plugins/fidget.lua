MiniDeps.later(function()
  MiniDeps.add({ source = "j-hui/fidget.nvim" })

  vim.keymap.set("n", "<leader>nh", "<cmd>Fidget history<CR>", { desc = "Notification history" })
  vim.keymap.set("n", "<leader>ns", "<cmd>Fidget suppress<CR>", { desc = "Notification supress" })

  require("fidget").setup({
    progress = {
      display = {
        done_ttl = 5,
        done_icon = " ",
      },
    },

    notification = {
      override_vim_notify = true,
      window = {
        x_padding = 0,
        y_padding = 0,
        normal_hl = "Comment",
      },
    },
  })
end)
