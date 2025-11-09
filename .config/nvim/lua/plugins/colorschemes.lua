MiniDeps.now(function()
  MiniDeps.add({ source = "folke/tokyonight.nvim" })

  require("tokyonight").setup({
    transparent = false,
    styles = {
      functions = { italic = true },
    },

    on_colors = function(colors)
      colors.bg = "#232634"
      colors.bg_dark = "#232634"
      colors.bg_float = "#292c3c"
      colors.bg_popup = "#292c3c"
      colors.bg_search = "#292c3c"
      colors.bg_sidebar = "#292c3c"
      colors.bg_statusline = "#292c3c"
    end,
  })

  -- vim.cmd.colorscheme("tokyonight-moon")
end)
