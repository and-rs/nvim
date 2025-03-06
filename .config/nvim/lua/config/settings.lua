vim.loader.enable()
vim.opt.mouse = ""

vim.opt.wrap = true
vim.opt.wrapmargin = 80
vim.opt.linebreak = true

-- remove eof character
vim.opt.fillchars = { eob = " " }

-- Save undo history
vim.opt.undofile = true

-- always number line
vim.opt.nu = true

-- incremental search
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- term colors
vim.opt.termguicolors = true

-- least amount of lines while scrolling is 10
vim.opt.scrolloff = 999
vim.opt.signcolumn = "yes"

-- fast update
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
-- vim.opt.list = true
-- vim.opt.listchars = { tab = "· ", trail = " ", nbsp = "␣" }
