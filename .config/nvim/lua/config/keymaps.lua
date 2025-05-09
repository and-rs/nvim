local map = function(mode, keys, action, desc)
  local description = ""
  if desc then
    description = desc
  end
  vim.keymap.set(mode, keys, action, { desc = description, silent = true, noremap = true })
end

local wrap_with_markdown = function()
  local content = vim.fn.getreg("+")
  local filetype = vim.bo.filetype == "typescriptreact" and "jsx" or vim.bo.filetype
  local path = vim.fn.expand("%")
  local result = table.concat({ "- ", path, "\n```", filetype, "\n", content, "```" })
  vim.fn.setreg("+", result)
end

vim.g.mapleader = " "

-- search visual selection (very nice)
map("v", "//", [[y/\V<C-R>=escape(@",'/\')<cr><cr>]], "Search visual selection")

-- repeat last macro
map("n", "Q", "@@", "Repeat last macro")

-- quickfix navigation
map("n", "]q", "<cmd>cnext<CR>", "Next quickfix item")
map("n", "[q", "<cmd>cprev<CR>", "Prev quickfix item")

-- better end and start of the line
map({ "n", "v" }, "j", "gj", "Up")
map({ "n", "v" }, "k", "gk", "Down")
map({ "n", "v" }, "L", "g$", "End of the line")
map({ "n", "v" }, "H", "g^", "Start of the line")

-- replacing C-i because it mimics Tab
map("n", "<C-t>", "<C-i>")

-- move with J and K ith indents
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- better terminal remaps
map({ "c", "i", "t" }, "<c-d>", "<Del>")
map({ "c", "i", "t" }, "<c-f>", "<Right>")
map({ "c", "i", "t" }, "<c-b>", "<Left>")

-- terminal 'unbinds'
map({ "c", "i", "t" }, "<c-j>", "<nop>")
map({ "c", "i", "t" }, "<c-k>", "<nop>")
map({ "n", "v", "i" }, "<c-l>", "<nop>")

-- keep cursor centered
map("n", "J", "mzJ`z", "Move current line up")
map("n", "n", "nzzzv", "Next result in search /")
map("n", "N", "Nzzzv", "Previous result in search /")

-- next greatest remap ever : asbjornHaland (yanking and pasting)
map("v", "<leader>y", [["+y]], "Yank to clipboard")
map("n", "<leader>yy", [["+yy]], "Yank line to clipboard")
map("n", "<leader>Y", [["+yg_]], "Yank to end of line to clipboard")
map({ "n", "v", "x" }, "<leader>p", '"+p', "Paste from clipboard")

-- yank and format selection to markdown automagically
map("n", "<leader>mf", function()
  vim.cmd('normal! ggVG"+y')
  wrap_with_markdown()
end, "Yank file with filename as heading and wrap in md fence")

map("v", "<leader>ms", function()
  vim.cmd('normal! "+y')
  wrap_with_markdown()
end, "Yank selection with filename as heading and wrap in markdown")

-- indow management
map("n", "<leader>wv", "<C-w>v", "Split window vertically")
map("n", "<leader>wh", "<C-w>s", "Split window horizontally")
map("n", "<leader>we", "<C-w>=", "Make splits equal size")
map("n", "<leader>wr", "<C-w>r", "Rotate splits")
map("n", "<leader>wh", "<C-w>H", "Send split to the right")
map("n", "<leader>wj", "<C-w>J", "Send split to the botton")
map("n", "<leader>wk", "<C-w>K", "Send split to the top")
map("n", "<leader>wl", "<C-w>L", "Send split to the left")
map("n", "<leader>wx", "<cmd>close<CR>", "Close current split")
map("n", "<leader>wo", "<cmd>on<CR>", "Close all other windows")

-- tab management
map("n", "<leader>to", "<cmd>tabnew<CR>", "Open new tab")
map("n", "<leader>tx", "<cmd>tabclose<CR>", "Close current tab")
map("n", "<leader>tn", "<cmd>tabn<CR>", "Go to next tab")
map("n", "<leader>tp", "<cmd>tabp<CR>", "Go to previous tab")
map("n", "<leader>tf", "<cmd>tabnew %<CR>", "Open current buffer in new tab")
