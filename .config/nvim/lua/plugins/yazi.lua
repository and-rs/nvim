return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    {
      "<leader>fe",
      mode = { "n", "v" },
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
    },
  },
  opts = {
    open_for_directories = true,
    keymaps = {
      show_help = "<f1>",
      cycle_open_buffers = "<tab>",
      open_file_in_tab = "<c-t>",
    },
    floating_window_scaling_factor = { height = 0.92, width = 1 },
    yazi_floating_window_border = "rounded",
  },
  init = function()
    vim.g.loaded_netrwPlugin = 1
  end,
}
