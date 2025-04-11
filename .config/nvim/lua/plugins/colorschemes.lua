return {
  {
    "folke/tokyonight.nvim",
    -- enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        transparent = false,
        on_colors = function(colors)
          colors.bg = "#0D1017"
          colors.bg_dark = "#0D1017"
          colors.bg_float = "#131621"
          colors.bg_popup = "#131621"
          colors.bg_search = "#131621"
          colors.bg_sidebar = "#131621"
          colors.bg_statusline = "#131621"
        end,
        styles = {
          functions = { italic = true },
        },
      })
      vim.cmd.colorscheme("tokyonight-moon")
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        compile = false, -- enable compiling the colorscheme
        undercurl = true, -- enable undercurls
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true },
        statementStyle = { bold = true },
        typeStyle = {},
        transparent = false, -- do not set background color
        dimInactive = true, -- dim inactive window `:h hl-NormalNC`
        terminalColors = true, -- define vim.g.terminal_color_{0,17}
        colors = { -- add/modify theme and palette colors
          palette = {},
          theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
        },
        overrides = function(colors) -- add/modify highlights
          return {}
        end,
      })

      -- setup must be called before loading
      -- vim.cmd("colorscheme kanagawa")
    end,
  },
}
