local color = require("config.coloring")
local treesitter = require("plugins.treesitter")
local statuscolumn_group = vim.api.nvim_create_augroup("StatusColumn", { clear = true })
vim.opt.cursorline = true

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = color.augroup,
  pattern = "*",
  callback = function()
    color.set("CursorLineSign", {
      bg = color.adjust_hex(color.get("CursorLine").bg, 0.8),
    })
    color.set("CursorLineNr", {
      fg = color.get("NvimCyan").fg,
      bg = color.adjust_hex(color.get("CursorLine").bg, 0.8),
      bold = true,
    })
    color.set("CursorLine", {
      bg = color.adjust_hex(color.get("CursorLine").bg, 0.8),
    })
    color.set("Folded", {
      fg = color.get("Visual").bg,
      bg = color.adjust_hex(color.get("Visual").bg, 0.7),
    })
  end,
})

local function render_border()
  return "▕ "
end

local function render_normal_statuscolumn()
  local line_number = vim.v.lnum
  if vim.v.virtnum ~= 0 then
    return "%s%=    " .. render_border()
  end
  return "%s%=" .. string.format("%4d", line_number) .. render_border()
end

local function clear_statuscolumn(win)
  vim.api.nvim_set_option_value("relativenumber", false, { win = win })
  vim.api.nvim_set_option_value("numberwidth", 1, { win = win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
  vim.api.nvim_set_option_value("statuscolumn", "%s", { win = win })
end

local function is_edit_window(buf, win)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
    return false
  end
  if vim.fn.win_gettype(win) ~= "" then
    return false
  end
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  if vim.wo[win].diff or vim.wo[win].previewwindow then
    return false
  end
  if vim.bo[buf].buftype ~= "" then
    return false
  end
  if vim.bo[buf].filetype == "" or not vim.bo[buf].modifiable or not vim.bo[buf].buflisted then
    return false
  end
  if not treesitter.has_highlighting(buf) then
    return false
  end
  return true
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "FileType", "WinEnter" }, {
  group = statuscolumn_group,
  callback = function(event)
    local buf = event.buf
    local win = vim.api.nvim_get_current_win()

    if not is_edit_window(buf, win) then
      clear_statuscolumn(win)
      return
    end

    vim.api.nvim_set_option_value("relativenumber", true, { win = win })
    vim.api.nvim_set_option_value("signcolumn", "yes:1", { win = win })
    vim.api.nvim_set_option_value(
      "statuscolumn",
      "%!v:lua.require('config.statuscolumn').render_normal_statuscolumn()",
      { win = win }
    )
  end,
})

return {
  render_border = render_border,
  render_normal_statuscolumn = render_normal_statuscolumn,
}