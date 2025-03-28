local map = vim.keymap.set

vim.g.mapleader = " "

-- repeat last macro
map("n", "Q", "@@", { desc = "Repeat last macro" })

-- quickfix navigation
map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
map("n", "[q", "<cmd>cprev<CR>", { desc = "Prev quickfix item" })

-- better end and start of the line
map({ "n", "v" }, "j", "gj", { desc = "Up" })
map({ "n", "v" }, "k", "gk", { desc = "Down" })
map({ "n", "v" }, "L", "g$", { desc = "End of the line" })
map({ "n", "v" }, "H", "g^", { desc = "Start of the line" })

-- replacing C-i because it mimics Tab
map("n", "<C-t>", "<C-i>")

-- move with J and K ith indents
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "" })

-- terminal 'unbinds'
map({ "c", "i", "t" }, "<c-j>", "<nop>")
map({ "c", "i", "t" }, "<c-k>", "<nop>")
map({ "n", "v", "i" }, "<c-l>", "<nop>")

-- keep cursor centered
map("n", "J", "mzJ`z", { desc = "Move current line up" })
map("n", "n", "nzzzv", { desc = "Next result in search /" })
map("n", "N", "Nzzzv", { desc = "Previous result in search /" })

-- next greatest remap ever : asbjornHaland (yanking and pasting)
map("v", "<leader>y", [["+y]], { desc = "Yank to clipboard" })
map("n", "<leader>yy", [["+yy]], { desc = "Yank line to clipboard" })
map("n", "<leader>Y", [["+yg_]], { desc = "Yank to end of line to clipboard" })
map({ "n", "v", "x" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })

-- indow management
map("n", "<leader>wv", "<C-w>v", { desc = "Split window vertically" })
map("n", "<leader>wh", "<C-w>s", { desc = "Split window horizontally" })
map("n", "<leader>we", "<C-w>=", { desc = "Make splits equal size" })
map("n", "<leader>wx", "<cmd>close<CR>", { desc = "Close current split" })
map("n", "<leader>wo", "<cmd>on<CR>", { desc = "Close all other windows" })

-- tab management
map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
map("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
map("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
map("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })
