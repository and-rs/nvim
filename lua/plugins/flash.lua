vim.schedule(function()
  vim.pack.add({ "https://github.com/and-rs/flash.nvim" })

  local color = require("config.coloring")
  local theme = require("config.theme")
  local p = theme.palette

  local function set_flash_rainbow(name, fg_color)
    if not fg_color then
      return
    end
    color.set(name, {
      fg = fg_color,
      bg = color.adjust_hex(fg_color, 0.2),
      bold = true,
      underline = true,
    })
  end

  if theme.sourced then
    local groups = {
      rainbow_red = p.red,
      rainbow_cyan = p.cyan,
      rainbow_blue = p.blue,
      rainbow_amber = p.yellow,
      rainbow_green = p.green,
      rainbow_violet = p.magenta,
      rainbow_fuchsia = p.red,
      rainbow_lime = p.green,
      rainbow_teal = p.cyan,
      rainbow_rose = p.red,
    }

    for name, fg in pairs(groups) do
      set_flash_rainbow(name, fg)
    end
  end

  require("flash").setup({
    label = {
      rainbow = {
        enabled = true,
        hl_overrides = {
          red = "rainbow_red",
          lime = "rainbow_lime",
          teal = "rainbow_teal",
          cyan = "rainbow_cyan",
          blue = "rainbow_blue",
          rose = "rainbow_rose",
          amber = "rainbow_amber",
          green = "rainbow_green",
          violet = "rainbow_violet",
          fuchsia = "rainbow_fuchsia",
        },
      },
    },
    search = {
      exclude = {
        "qf",
        "noice",
        "notify",
        "cmp_menu",
        "flash_prompt",
        function(win)
          return not vim.api.nvim_win_get_config(win).focusable
        end,
      },
    },
    highlight = {
      backdrop = true,
      matches = true,
      priority = 5000,
    },
    modes = {
      char = {
        enabled = false,
      },
    },
    prompt = {
      enabled = true,
      prefix = { { "jump: ", "FlashPromptIcon" } },
    },
  })

  vim.keymap.set({ "n", "x", "o" }, "s", function()
    require("flash").jump()
  end, { desc = "Flash" })

  vim.keymap.set({ "n", "x", "o" }, "<C-t>", function()
    require("flash").treesitter()
  end, { desc = "Flash Treesitter" })

  vim.keymap.set("o", "r", function()
    require("flash").remote()
  end, { desc = "Remote Flash" })

  vim.keymap.set({ "o", "x" }, "R", function()
    require("flash").treesitter_search()
  end, { desc = "Treesitter Search" })

  vim.keymap.set({ "c" }, "<c-s>", function()
    require("flash").toggle()
  end, { desc = "Toggle Flash Search" })
end)
