MiniDeps.now(function()
  MiniDeps.add({ source = "aserowy/tmux.nvim" })

  require("tmux").setup({
    copy_sync = {
      enable = true,
      ignore_buffers = { empty = false },
      redirect_to_clipboard = false,
      register_offset = 0,

      sync_registers_keymap_put = true,
      sync_registers_keymap_reg = true,
      sync_clipboard = true,
      sync_registers = true,
      sync_deletes = true,
      sync_unnamed = true,
    },
    navigation = {
      enable_default_keybindings = false,
      cycle_navigation = false,
      persist_zoom = true,
    },
    resize = {
      enable_default_keybindings = false,
      resize_step_x = 1,
      resize_step_y = 1,
    },
    swap = {
      cycle_navigation = false,
      enable_default_keybindings = false,
    },
  })

  vim.keymap.set("n", "<A-h>", require("tmux").resize_left)
  vim.keymap.set("n", "<A-j>", require("tmux").resize_bottom)
  vim.keymap.set("n", "<A-k>", require("tmux").resize_top)
  vim.keymap.set("n", "<A-l>", require("tmux").resize_right)

  vim.keymap.set("n", "<C-h>", require("tmux").move_left)
  vim.keymap.set("n", "<C-j>", require("tmux").move_bottom)
  vim.keymap.set("n", "<C-k>", require("tmux").move_top)
  vim.keymap.set("n", "<C-l>", require("tmux").move_right)
end)
