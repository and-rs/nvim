return {
  "folke/tokyonight.nvim",
  lazy = false,
  enabled = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      transparent = false,
      -- on_colors = function(colors)
      --   colors.bg = "#0D1017"
      --   colors.bg_dark = "#0D1017"
      --   colors.bg_float = "#131621"
      --   colors.bg_popup = "#131621"
      --   colors.bg_search = "#131621"
      --   colors.bg_sidebar = "#131621"
      --   colors.bg_statusline = "#131621"
      -- end,
      styles = {
        functions = { italic = true },
      },
    })
    vim.cmd.colorscheme("tokyonight")
  end,
}
