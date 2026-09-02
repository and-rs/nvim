-- 1st
require("config.settings")
require("config.theme")
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

require("plugins.hlchunk")
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
vim.keymap.set({ "c", "t" }, "<M-BS>", "<C-u>")

if vim.g.neovide then
  vim.o.linespace = 9
  vim.g.neovide_text_gamma = 1.0
  vim.g.neovide_text_contrast = 0.5
  vim.o.guifont = "MD IO Trial:h13"

  vim.g.neovide_padding_top = 4
  vim.g.neovide_padding_bottom = 0

  vim.g.neovide_floating_shadow = true
  vim.g.neovide_floating_z_height = 2
  vim.g.neovide_underline_stroke_scale = 2

  local function paste()
    vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
  end

  vim.keymap.set({ "n", "i", "v", "c", "t" }, "<M-v>", paste, { silent = true, desc = "Paste" })
end
