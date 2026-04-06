-- 1st
require("config.settings")
require("config.keymaps")

-- Force Neovim to use undercurls and underline colors in tmux
vim.cmd([[
  let &t_Cs = "\e[4:3m"
  let &t_Ce = "\e[4:0m"
]])

-- 2nd
require("config.highlights")
require("config.statuscolumn")
require("config.tabline")

-- 3rd
require("config.profiling")
require("ai.main")

Deferred_group = vim.api.nvim_create_augroup("Deferred", { clear = true })
-- require all plugin files
local function require_plugins()
  local dir = vim.fn.stdpath("config") .. "/lua/plugins"
  for name, t in vim.fs.dir(dir) do
    if t == "file" and name:sub(-4) == ".lua" then
      require("plugins." .. name:sub(1, -5))
    end
  end
end

require("vim._core.ui2").enable({ enable = true })
vim.g.smart_splits_multiplexer_integration = "tmux"

-- neovide
if vim.g.neovide then
  vim.opt.linespace = 11
  vim.g.terminal_color_0 = "#1b1e25"
  vim.g.terminal_color_8 = "#79839c"
  vim.g.terminal_color_1 = "#ffc0b9"
  vim.g.terminal_color_9 = "#ffc0b9"
  vim.g.terminal_color_2 = "#b3f6c0"
  vim.g.terminal_color_10 = "#b3f6c0"
  vim.g.terminal_color_3 = "#fce094"
  vim.g.terminal_color_11 = "#fce094"
  vim.g.terminal_color_4 = "#a6dbff"
  vim.g.terminal_color_12 = "#a6dbff"
  vim.g.terminal_color_5 = "#ffcaff"
  vim.g.terminal_color_13 = "#ffcaff"
  vim.g.terminal_color_6 = "#8cf8f7"
  vim.g.terminal_color_14 = "#8cf8f7"
  vim.g.terminal_color_7 = "#eef1f8"
  vim.g.terminal_color_15 = "#eef1f8"

  vim.g.neovide_input_use_logo = true
  vim.keymap.set({ "c", "t" }, "<D-BS>", "<C-w>")
  vim.keymap.set({ "c", "t" }, "<M-BS>", "<M-C-H>")
end

require_plugins()
