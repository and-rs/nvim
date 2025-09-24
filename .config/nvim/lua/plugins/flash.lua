MiniDeps.now(function()
  MiniDeps.add({ source = "folke/flash.nvim" })

  require("flash").setup({
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

  vim.keymap.set({ "n", "x", "o" }, "<Tab>", function()
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
