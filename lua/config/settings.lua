vim.loader.enable()
vim.opt.mouse = ""
vim.g.mapleader = " "
vim.opt.background = "dark"

-- this is a test
-- always centered
vim.opt.scrolloff = 999

-- no folds in diff
-- vim.o.diffopt = "context:9999"

-- no mode on the cmd line, only shown on lualine
vim.opt.showmode = false

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

-- per project shada
local shada_dir = vim.fn.stdpath("state") .. "/shada/"
vim.fn.mkdir(shada_dir, "p")
local project_id = vim.fn.sha256(vim.fn.getcwd()):sub(1, 8)
vim.opt.shadafile = shada_dir .. project_id .. ".shada"
