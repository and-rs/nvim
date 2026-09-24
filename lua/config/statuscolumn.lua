local color = require("config.coloring")
local statuscolumn_group = vim.api.nvim_create_augroup("StatusColumn", { clear = true })
local eob_ns = vim.api.nvim_create_namespace("statuscolumn_eob")
vim.opt.cursorline = true

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = color.augroup,
  pattern = "*",
  callback = function()
    local theme = require("config.theme")
    if not theme.sourced then
      return
    end
    local p = theme.palette
    local cursor_bg = p.black
    color.set("CursorLineSign", {
      bg = cursor_bg,
    })
    color.set("CursorLineNr", {
      fg = p.cyan,
      bg = cursor_bg,
      bold = true,
    })
    color.set("CursorLine", {
      bg = cursor_bg,
    })
    color.set("Folded", {
      fg = p.selection,
      bg = color.adjust_hex(p.selection, 0.7),
    })

    color.set("SignColumn", {
      fg = p.surface3,
      bg = p.black,
    })
    color.set("LineNr", {
      fg = color.adjust_hex(p.surface5, 0.8),
      bg = p.black,
    })
    color.set("Border", {
      fg = p.surface3,
      bg = p.black,
    })
    color.set("EobBar", {
      fg = p.surface3,
      bg = "NONE",
    })
  end,
})

local side_border = "🮇"
local bottom_border = "▔"

local function render_border()
  return "%#Border#" .. side_border .. "%#None# "
end

local function render_zero_border()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    return "%#CursorLineNr#" .. side_border .. "%#Normal# "
  end

  return "%#CursorLineNr#" .. side_border .. " "
end

local function number_width()
  local win = vim.g.statusline_winid or 0
  local buf = vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) or 0
  if buf == 0 or not vim.api.nvim_buf_is_valid(buf) then
    return 4
  end
  return math.max(4, #tostring(vim.api.nvim_buf_line_count(buf)))
end

local function update_eob_bar(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if vim.bo[buf].buftype ~= "" then
    vim.api.nvim_buf_clear_namespace(buf, eob_ns, 0, -1)
    return
  end
  vim.api.nvim_buf_set_extmark(buf, eob_ns, vim.api.nvim_buf_line_count(buf) - 1, 0, {
    id = 1,
    virt_lines = { { { "", "EobBar" } } },
  })
end

local function render_normal_statuscolumn()
  local line_number = vim.v.lnum
  local width = number_width()

  if vim.v.virtnum < 0 then
    return "%#EobBar#" .. string.rep(bottom_border, 2 + width + 1) .. "%#None# "
  end
  if vim.v.virtnum ~= 0 then
    return "%#LineNr#%=" .. string.rep(" ", width) .. render_border()
  end
  if vim.v.relnum == 0 then
    return "%s%=%#CursorLineNr#"
      .. string.format("%" .. width .. "d", line_number)
      .. render_zero_border()
  end
  return "%s%=%#LineNr#" .. string.format("%" .. width .. "d", line_number) .. render_border()
end

local function clear_statuscolumn(win)
  vim.api.nvim_set_option_value("number", false, { win = win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
  vim.api.nvim_set_option_value("statuscolumn", "", { win = win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win })
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

    vim.api.nvim_set_option_value("number", true, { win = win })
    vim.api.nvim_set_option_value("relativenumber", true, { win = win })
    vim.api.nvim_set_option_value("signcolumn", "yes:1", { win = win })
    vim.api.nvim_set_option_value(
      "statuscolumn",
      "%!v:lua.require('config.statuscolumn').render_normal_statuscolumn()",
      { win = win }
    )
    update_eob_bar(buf)
  end,
})

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  group = statuscolumn_group,
  callback = function(event)
    update_eob_bar(event.buf)
  end,
})

return {
  render_border = render_border,
  render_normal_statuscolumn = render_normal_statuscolumn,
}
