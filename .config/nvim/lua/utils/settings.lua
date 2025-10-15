vim.loader.enable()
vim.opt.mouse = ""

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

vim.opt.background = "dark"

-- indent symbols
-- tab cannot be less than 2
vim.opt.list = true
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("ScrollOffEOF", { clear = true }),
  callback = function()
    vim.wo.scrolloff = 0

    local win_h = vim.api.nvim_win_get_height(0)
    local cur_line = vim.fn.line(".")
    local half_height = math.floor(win_h / 2)
    local desired_topline = math.max(1, cur_line - half_height)

    vim.fn.winrestview({ topline = desired_topline })
  end,
})
