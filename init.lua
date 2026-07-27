-- 1st
require("config.settings")
require("config.keymaps")

-- Force Neovim to use undercurls and underline colors in tmux
vim.cmd("set shell=bash")
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
Deferred_group = vim.api.nvim_create_augroup("Deferred", { clear = true })

-- require("plugins.hlchunk")

require("plugins.alpha")
require("plugins.autotag")
require("plugins.blink-cmp")
require("plugins.comment")
require("plugins.conform")
require("plugins.csvview")
require("plugins.fidget")
require("plugins.flash")
require("plugins.fzf")
require("plugins.git-signs")
require("plugins.lsp-config")
require("plugins.lualine")
require("plugins.quickfix")
require("plugins.scissors")
require("plugins.surround")
require("plugins.tmux")
require("plugins.tokyonight")
require("config.folding")
require("plugins.typescript")
require("plugins.visual-whitespace")
require("plugins.whichkey")
require("plugins.yazi")
require("plugins.diff")
require("plugins.treesitter")

-- when I open nu term buffer in neovim
vim.api.nvim_create_autocmd({ "FileType", "VimEnter" }, {
  pattern = { "nu" },
  callback = function()
    vim.treesitter.start()
  end,
})

require("vim._core.ui2").enable({ enable = true })
vim.g.smart_splits_multiplexer_integration = "tmux"

vim.keymap.set({ "c", "t" }, "<D-BS>", "<C-w>")
vim.keymap.set({ "c", "t" }, "<M-BS>", "<M-C-H>")
