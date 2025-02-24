return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    require("which-key").add({
      { "ma", mode = "n", desc = "Harpoon add" },
      { "M", mode = "n", desc = "Harpoon menu" },
      { "S", mode = "v", desc = "Add surround visual" },
      { "<leader>c", group = "Column" },
      { "<leader>l", group = "LSP" },
      { "<leader>n", group = "Notifications" },
      { "<leader>f", group = "Filetree" },
      { "<leader>m", group = "Format or Linting" },
      { "<leader>r", group = "Rename" },
      { "<leader>s", group = "Search" },
      { "<leader>t", group = "Tabs" },
      { "<leader>u", group = "Buffers" },
      { "<leader>w", group = "Wins" },
      { "<leader>g", group = "Git Diff" },
    })
  end,
  opts = {
    preset = "helix",
    plugins = {
      presets = {
        windows = false,
      },
    },
    win = {
      height = { max = 20 },
      border = "single",
      padding = { 0, 1 },
    },
    keys = {
      scroll_down = "<c-f>",
      scroll_up = "<c-u>",
    },
    replace = {
      key = {
        { "<BS>", "ret" },
        { "<Space>", "spc" },
        { "<S%-Tab>", "stab" },
      },
    },
    icons = {
      rules = false,
      separator = "→",
    },
    show_help = false,
  },
}
