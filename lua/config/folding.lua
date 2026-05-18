local map = require("config.map").set
local treesitter = require("plugins.treesitter")
local group = vim.api.nvim_create_augroup("Folding", { clear = true })

local function should_persist_view(buffer_number)
  return vim.bo[buffer_number].buftype == "" and vim.api.nvim_buf_get_name(buffer_number) ~= ""
end

local function toggle_all_folds()
  vim.w.folds_closed = not vim.w.folds_closed
  if vim.w.folds_closed then
    vim.cmd("normal! zM")
    return
  end
  vim.cmd("normal! zR")
end

local function jump_closed_fold(direction)
  local move = direction == "next" and "zj" or "zk"
  local max_jumps = vim.api.nvim_buf_line_count(0)

  for _ = 1, max_jumps do
    local before = vim.api.nvim_win_get_cursor(0)[1]
    vim.cmd("normal! " .. move)
    local after = vim.api.nvim_win_get_cursor(0)[1]

    if after == before then
      return
    end

    if vim.fn.foldclosed(after) ~= -1 then
      return
    end
  end
end

vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldtext = ""
vim.opt.viewoptions:append("folds")
vim.opt.foldopen:remove("hor")

map("n", "<leader>uf", "za", "Toggle fold", { silent = true })
map("n", "<leader>uF", toggle_all_folds, "Toggle all folds", { silent = true })
map("n", "<leader>un", function()
  jump_closed_fold("next")
end, "Next closed fold", { silent = true })
map("n", "<leader>up", function()
  jump_closed_fold("prev")
end, "Previous closed fold", { silent = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "*",
  callback = function(event)
    local filetype = vim.bo[event.buf].filetype
    if treesitter.has_parser(filetype) then
      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      return
    end
    vim.opt_local.foldmethod = "indent"
    vim.opt_local.foldexpr = "0"
  end,
})

vim.api.nvim_create_autocmd("BufWinLeave", {
  group = group,
  pattern = "*",
  callback = function(event)
    if should_persist_view(event.buf) then
      vim.cmd("silent! mkview")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = group,
  pattern = "*",
  callback = function(event)
    if should_persist_view(event.buf) then
      vim.cmd("silent! loadview")
    end
  end,
})