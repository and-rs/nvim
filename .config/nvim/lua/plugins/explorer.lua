return {
  "folke/snacks.nvim",
  -- enabled = false,
  config = function()
    require("snacks").setup({
      explorer = {
        enabled = true,
        replace_netrw = true,
      },
      picker = {
        icons = {
          diagnostics = {
            Error = " ×",
            Warn = " •",
            Hint = " •",
            Info = " •",
          },
          git = {
            commit = "󰜘",
            conflict = "",
            staged = "",
            added = "",
            deleted = "",
            modified = "",
            ignored = "",
            unstaged = "",
            renamed = "",
            untracked = "",
          },
        },
        layout = {
          auto_hide = { "input" },
        },
        ui_select = false,
        sources = {
          explorer = {
            include = { ".env*" },
            auto_close = true,
            layout = {
              layout = { position = "right" },
              auto_hide = { "input" },
            },
            win = {
              list = {
                keys = {
                  ["<c-s>"] = { "edit_vsplit", mode = { "i", "n" } },
                  ["x"] = "explorer_move",
                  ["c-t"] = false,
                  ["m"] = false,
                  ["P"] = false,
                },
              },
            },
          },
        },
      },
    })

    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    local map = vim.keymap
    map.set("n", "<leader>fe", "<cmd>lua Snacks.explorer()<cr>", { desc = "File Explorer" })
  end,
}
