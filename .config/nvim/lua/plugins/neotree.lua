return {
  dir = "~/dev/neo-tree.nvim",
  enabled = false,
  -- "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },

  config = function()
    local keymap = vim.keymap
    keymap.set(
      "n",
      "<leader>fe",
      "<cmd>Neotree toggle focus right reveal_force_cwd<cr>",
      { desc = "File Explorer" }
    )

    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require("neo-tree").setup({
      retain_hidden_root_indent = false,
      hide_root_node = true,

      default_component_configs = {
        icon = {
          folder_closed = "",
          folder_open = "",
          folder_empty = "",
        },
        indent = {
          indent_size = 2,
          marker_start_level = 1,
          -- with_expanders = true,
          -- expander_collapsed = "»",
          -- expander_expanded = "↓",
        },
        modified = {
          symbol = "*",
        },
        diagnostics = {
          symbols = {
            hint = "h",
            info = "i",
            warn = "w",
            error = "e",
          },
        },
        git_status = {
          symbols = {
            -- Change type
            added = "",
            deleted = "",
            modified = "",
            renamed = "",
            -- Status type
            untracked = "",
            unstaged = "",
            ignored = "",
            staged = "",
            conflict = "",
          },
        },
      },

      popup_border_style = "single",
      event_handlers = { -- Close neo-tree when opening a file.
        {
          event = "file_opened",
          handler = function()
            require("neo-tree").close_all()
          end,
        },
      },

      filesystem = {
        filtered_items = {
          show_hidden_count = false,
          group_empty_dirs = true,
          hide_dotfiles = false,
          always_show = {
            ".envrc",
            ".env",
          },
          never_show = {
            ".DS_Store",
            ".git",
            "__pycache__",
          },
        },
        bind_to_cwd = true, -- true creates a 2-way binding between vim's cwd and neo-tree's root
        window = {
          mappings = {
            ["<C-v>"] = "open_vsplit",
            ["n"] = "toggle_node",
            ["<space>"] = "none",
          },
        },
      },
    })

    vim.keymap.set("n", "0", "<cmd>Lazy reload neo-tree.nvim<CR>", { desc = "Reload neo-tree" })
  end,
}
