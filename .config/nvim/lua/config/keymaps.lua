local map = vim.keymap.set
local del = vim.keymap.del

vim.g.mapleader = " "

-- repeat last macro
map("n", "Q", "@@", { silent = true })

-- quickfix navigation
map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
map("n", "[q", "<cmd>cprev<CR>", { desc = "Prev quickfix item" })

-- better end and start of the line
map({ "n", "v" }, "L", "$", { desc = "End of the line" })
map({ "n", "v" }, "H", "^", { desc = "Start of the line" })

-- replacing C-i because it mimics Tab
map("n", "<C-t>", "<C-i>")

-- move with J and K with indents
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
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map({ "n", "v" }, "<leader>p", [["+p]], { desc = "Paste from system clipboard" })

-- diagnostic window unbinds
del("n", "<C-w>d")
del("n", "<C-w><C-d>")
map("n", "<C-w>", "<nop>")

-- window management
map("n", "<leader>wv", "<C-w>v", { desc = "Split window vertically" })
map("n", "<leader>wh", "<C-w>s", { desc = "Split window horizontally" })
map("n", "<leader>we", "<C-w>=", { desc = "Make splits equal size" })
map("n", "<leader>wx", "<cmd>close<CR>", { desc = "Close current split" })

-- tab management
map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
map("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
map("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
map("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })
