local function map(mode, keys, action, desc, opts)
  local defaults = {
    desc = desc or "",
    noremap = true,
  }

  local merged = vim.tbl_extend("force", defaults, opts or {})
  vim.keymap.set(mode, keys, action, merged)
end

vim.g.mapleader = " "

-- better manual indenting
map("v", "<", "<gv<C-o>'<", "Inner indent while remaining in visual mode")
map("v", ">", ">gv<C-o>'<", "Outer indent while remaining in visual mode")

-- search visual selection (very nice)
map("v", "//", [[y:let@/='\V'.escape(@",'/\\')<CR>]], "Search visual selection", { silent = true })

-- repeat last macro
map("n", "Q", "@@", "Repeat last macro")

-- quickfix navigation
map("n", "]q", "<cmd>cnext<CR>", "Next quickfix item")
map("n", "[q", "<cmd>cprev<CR>", "Prev quickfix item")

-- better up and down
map({ "n", "v" }, "j", "gj", "Up")
map({ "n", "v" }, "k", "gk", "Down")

-- move with J and K ith indents
map("v", "J", ":m '>+1<CR>gv=gv", "Move line down", { silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", "Move line up", { silent = true })

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
map("n", "<leader>wo", "<cmd>on | diffoff<CR>", "Close all other windows")

-- tab management
map("n", "<leader>to", "<cmd>tabnew<CR>", "Open new tab")
map("n", "<leader>tx", "<cmd>tabclose<CR>", "Close current tab")
map("n", "<leader>tn", "<cmd>tabn<CR>", "Go to next tab")
map("n", "<leader>tp", "<cmd>tabp<CR>", "Go to previous tab")
map("n", "<leader>tf", "<cmd>tabnew %<CR>", "Open current buffer in new tab")

local wrap_with_markdown = function(content)
  local path = vim.fn.expand("%:.")
  local filetype = vim.bo.filetype == "typescriptreact" and "jsx" or vim.bo.filetype
  local result = table.concat({ "- ", path, "\n```", filetype, "\n", content, "```" })
  vim.fn.setreg("+", result)
end

map("n", "<leader>mf", function()
  vim.cmd('normal! ggVG"ny')
  local content = vim.fn.getreg("n")
  wrap_with_markdown(content)
  vim.notify("Entire file copied with MD formatting")
end, "Yank file with filename as heading and wrap in md fence")

map("v", "<leader>ms", function()
  vim.cmd('normal! "ny')
  local content = vim.fn.getreg("n")
  wrap_with_markdown(content)
  vim.notify("Selection copied with MD formatting")
end, "Yank selection with filename as heading and wrap in markdown")
