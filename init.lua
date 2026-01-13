require("config.highlights")
require("config.tabline")
require("config.statuscolumn")
require("config.settings")
require("config.keymaps")
require("config.profile")

-- install mini.deps
local path_package = vim.fn.stdpath("data") .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.deps"
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.deps`" | redraw')
  local clone_cmd =
    { "git", "clone", "--filter=blob:none", "https://github.com/nvim-mini/mini.deps", mini_path }
  vim.fn.system(clone_cmd)
  vim.cmd("packadd mini.deps | helptags ALL")
  vim.cmd('echo "Installed `mini.deps`" | redraw')
end

-- setup mini.deps
require("mini.deps").setup({ path = { package = path_package } })
MiniDeps = require("mini.deps")

-- require all plugin files
local function require_plugins()
  local dir = vim.fn.stdpath("config") .. "/lua/plugins"
  for name, t in vim.fs.dir(dir) do
    if t == "file" and name:sub(-4) == ".lua" then
      require("plugins." .. name:sub(1, -5))
    end
  end
end

vim.g.smart_splits_multiplexer_integration = "tmux"

--neovide
if vim.g.neovide then
  vim.opt.linespace = 14
  vim.g.terminal_color_0 = "#07080d"
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
  vim.g.terminal_color_7 = "#1b1e25"
  vim.g.terminal_color_15 = "#eef1f8"

  vim.g.neovide_input_use_logo = true
  vim.keymap.set({ "c", "t" }, "<D-BS>", "<C-w>")
  vim.keymap.set({ "c", "t" }, "<M-BS>", "<M-C-H>")
end

require_plugins()
