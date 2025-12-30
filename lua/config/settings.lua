vim.loader.enable()
vim.opt.mouse = ""
vim.g.mapleader = " "

-- keep darkmode
vim.opt.background = "dark"

-- always centered
vim.opt.scrolloff = 999

-- no folds in diff
vim.o.diffopt = "context:9999"

-- no mode on the cmd line, only shown on lualine
vim.opt.showmode = false

-- folds
vim.opt.foldenable = false
vim.opt.foldmethod = "manual"

-- wrap
vim.opt.wrap = false
vim.opt.breakat = " "
vim.opt.linebreak = true

-- remove eof character
vim.opt.fillchars = { eob = "·" }
vim.opt.signcolumn = "yes"

-- Save undo history
vim.opt.undofile = true

-- always number line
vim.opt.nu = true

-- incremental search
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- term colors
vim.opt.termguicolors = true

-- fast updat
vim.opt.updatetime = 50

-- better indentation
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

-- Enable break indent
vim.opt.breakindent = true

-- Split direction
vim.opt.splitright = true
vim.opt.splitbelow = true

-- indent symbols
-- tab cannot be less than 2
vim.opt.list = true
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

-- share neovim's clipboard between instances
local shared_registers = vim.api.nvim_create_augroup("shared_registers", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = shared_registers,
  callback = function()
    vim.cmd("wshada!")
  end,
})
vim.api.nvim_create_autocmd("FocusGained", {
  group = shared_registers,
  callback = function()
    vim.cmd("rshada!")
  end,
})
