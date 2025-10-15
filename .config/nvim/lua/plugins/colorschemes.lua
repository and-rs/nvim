MiniDeps.now(function()
  MiniDeps.add({ source = "folke/tokyonight.nvim" })
  MiniDeps.add({ source = "projekt0n/github-nvim-theme" })

  require("github-theme").setup({})
  vim.cmd("colorscheme github_dark_default")

  require("tokyonight").setup({
    transparent = false,
    styles = {
      functions = { italic = true },
    },

    on_colors = function(colors)
      colors.bg = "#212330"
      colors.bg_dark = "#212330"
      colors.bg_float = "#252837"
      colors.bg_popup = "#252837"
      colors.bg_search = "#252837"
      colors.bg_sidebar = "#252837"
      colors.bg_statusline = "#252837"
    end,

    --   on_colors = function(colors)
    --     colors.red = "#C41C46"
    --     colors.red1 = "#C41C46"
    --     colors.error = "#C41C46"
    --
    --     colors["@markup.heading.8.markdown"] = {
    --       bold = true,
    --       fg = "#D60A44",
    --     }
    --     colors["@module.builtin"] = {
    --       fg = "#D60A44",
    --     }
    --     colors["@tag.javascript"] = {
    --       fg = "#D60A44",
    --     }
    --     colors["@tag.tsx"] = {
    --       fg = "#D60A44",
    --     }
    --     colors["@variable.builtin"] = {
    --       fg = "#D60A44",
    --     }
    --     BufferAlternateTarget = {
    --       fg = "#D60A44",
    --     }
    --     BufferCurrentTarget = {
    --       fg = "#D60A44",
    --     }
    --     BufferInactiveTarget = {
    --       fg = "#D60A44",
    --     }
    --     BufferVisibleTarget = {
    --       fg = "#D60A44",
    --     }
    --     GlyphPalette9 = {
    --       fg = "#D60A44",
    --     }
    --     RainbowDelimiterRed = {
    --       fg = "#D60A44",
    --     }
    --     Substitute = {
    --       bg = "#D60A44",
    --     }
    --
    --     colors.terminal = {
    --       black = "#d0d5e3",
    --       black_bright = "#777C92",
    --       red = "#C41C46",
    --       red_bright = "#C41C46",
    --       green = "#587539",
    --       green_bright = "#5c8524",
    --       yellow = "#A27629",
    --       yellow_bright = "#A27629",
    --       blue = "#2E7DE9",
    --       blue_bright = "#2E7DE9",
    --       magenta = "#9854F1",
    --       magenta_bright = "#9854F1",
    --       cyan = "#007EA8",
    --       cyan_bright = "#007EA8",
    --       white = "#3760BF",
    --       white_bright = "#3760BF",
    --     }
    --   end,
  })

  -- vim.cmd.colorscheme("tokyonight-moon")
end)
