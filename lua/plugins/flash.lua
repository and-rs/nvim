MiniDeps.later(function()
  MiniDeps.add({ source = "and-rs/flash.nvim" })

  local color = require("config.coloring")
  local function set_flash(name, base_hl)
    local fg_color = color.get(base_hl, "fg")
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

  local groups = {
    rainbow_red = "NvimRed",
    rainbow_lime = "NvimLime",
    rainbow_teal = "NvimTeal",
    rainbow_cyan = "NvimCyan",
    rainbow_blue = "NvimBlue",
    rainbow_rose = "NvimPink",
    rainbow_amber = "NvimYellow",
    rainbow_green = "NvimGreen",
    rainbow_violet = "NvimViolet",
    rainbow_fuchsia = "NvimFuchsia",
  }

  for name, base in pairs(groups) do
    set_flash(name, base)
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
