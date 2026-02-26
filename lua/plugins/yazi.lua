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
      cycle_open_buffers = "<tab>",
      open_file_in_tab = "<c-t>",
      open_file_in_vertical_split = "<nop>",
      open_file_in_horizontal_split = "<nop>",
    },
    highlight_groups = {
      hovered_buffer = { link = "Normal" },
    },
    highlight_hovered_buffers_in_same_directory = false,
    hooks = {
      yazi_closed_successfully = function()
        require("fff").scan_files()
      end,
      before_opening_window = function(window_options)
        window_options.row = 2
        window_options.width = dynamic_width()
        window_options.col = math.floor((vim.o.columns - dynamic_width()) / 2) - 1
      end,
    },
    floating_window_scaling_factor = {
      height = 18,
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
