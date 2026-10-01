local map = require("config.map").set

local function clean_and_parenthesize(opening)
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  for index, line in ipairs(lines) do
    lines[index] = line:gsub("%s*\\%s*$", "")
  end

  table.insert(lines, 1, opening or "(")
  table.insert(lines, ")")
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
  vim.api.nvim_input([[<C-\><C-n>]])
end

map("v", "<leader>N", function()
  clean_and_parenthesize("$env.TMP_CMD = (")
end, "Assign cleaned selection to TMP_CMD")
map("v", "<leader>n", clean_and_parenthesize, "Remove \\ and parenthesize")
