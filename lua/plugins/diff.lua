local function load()
  vim.pack.add({
    "https://github.com/MunifTanjim/nui.nvim",
    { src = "https://github.com/esmuellert/codediff.nvim" },
  })

  require("codediff").setup({
    highlights = {
      char_brightness = 1.2,
    },
    diff = {
      original_position = "right",
    },
  })

  local theme = require("config.theme")
  if theme.sourced then
    local cl = require("config.coloring")
    local p = theme.palette
    require("codediff").setup({
      highlights = {
        line_delete = cl.adjust_hex(p.red, 0.35),
        char_delete = cl.adjust_hex(p.red, 0.5),
        line_insert = cl.adjust_hex(p.green, 0.35),
        char_insert = cl.adjust_hex(p.green, 0.5),
      },
    })
  end

  vim.keymap.set("n", "<leader>gd", "<cmd>CodeDiff file HEAD<CR>", { desc = "Show Diff" })
end

vim.schedule(function()
  load()
end)
