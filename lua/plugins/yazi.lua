MiniDeps.now(function()
  MiniDeps.add({
    source = "mikavilpas/yazi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  })

  vim.g.loaded_netrwPlugin = 1

  local function dynamic_width()
    return math.min(100, vim.o.columns - 6)
  end

  require("yazi").setup({
    open_for_directories = true,
    keymaps = {
      show_help = "<f1>",
      open_file_in_tab = "<c-t>",
      send_to_quickfix_list = "<c-q>",
      open_file_in_vertical_split = "<c-v>",
      open_file_in_horizontal_split = "<c-h>",

      grep_in_directory = "<nop>",
      cycle_open_buffers = "<nop>",
      open_and_pick_window = "<nop>",
      replace_in_directory = "<nop>",
      copy_relative_path_to_selected_files = "<nop>",

      change_working_directory = "<c-p>",
    },
    highlight_groups = {
      hovered_buffer = { link = "Normal" },
    },
    highlight_hovered_buffers_in_same_directory = false,
    hooks = {
      yazi_closed_successfully = function()
        if vim.fn.getcwd() == vim.env.HOME then
          require("fff").scan_files()
        end
      end,
      before_opening_window = function(window_options)
        window_options.row = 2
        window_options.width = dynamic_width()
        window_options.col = math.floor((vim.o.columns - dynamic_width()) / 2) - 1
      end,
    },
    floating_window_scaling_factor = {
      height = 20,
      width = dynamic_width(),
    },
  })

  vim.keymap.set(
    { "n", "v" },
    "<leader>fe",
    "<cmd>Yazi<cr>",
    { desc = "Open yazi at the current file" }
  )

  local color = require("config.coloring")
  color.set("YaziFloatBorder", { link = "NormalFloat" })
  color.set("YaziFloat", { bg = color.get("NormalFloat", "bg") })
end)
