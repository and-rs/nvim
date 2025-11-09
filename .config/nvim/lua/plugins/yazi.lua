MiniDeps.now(function()
  MiniDeps.add({
    source = "and-rs/yazi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  })

  vim.g.loaded_netrwPlugin = 1

  require("yazi").setup({
    open_for_directories = true,
    keymaps = {
      show_help = "<f1>",
      cycle_open_buffers = "<tab>",
      open_file_in_tab = "<c-t>",
    },
    floating_window_scaling_factor = { height = 0.7, width = 0.8 },
  })

  vim.keymap.set(
    { "n", "v" },
    "<leader>fe",
    "<cmd>Yazi<cr>",
    { desc = "Open yazi at the current file" }
  )
end)
