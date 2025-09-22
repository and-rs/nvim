require("utils.highlights")
require("utils.settings")
require("utils.keymaps")
require("utils.tailwind")
require("utils.profile")

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

require_plugins()
