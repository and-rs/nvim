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
      open_file_in_vertical_split = "<nop>",
      open_file_in_horizontal_split = "<nop>",
    },
    highlight_groups = {
      hovered_buffer = { link = "Normal" },
    },
    highlight_hovered_buffers_in_same_directory = false,
    floating_window_scaling_factor = {
      height = 0.7,
      width = 0.8,
      row = 2,
    },
  })

  vim.keymap.set(
    { "n", "v" },
    "<leader>fe",
    "<cmd>Yazi<cr>",
    { desc = "Open yazi at the current file" }
  )
end)
