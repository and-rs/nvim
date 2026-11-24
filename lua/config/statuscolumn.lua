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
      fg = p.surface2,
      bg = p.black,
    })
    color.set("LineNr", {
      fg = color.adjust_hex(p.surface5, 0.8),
      bg = p.black,
    })
    color.set("Border", {
      fg = p.surface2,
      bg = p.black,
    })
    color.set("EobBar", {
      fg = p.surface2,
      bg = "NONE",
    })
    color.set("EobBarActive", {
      fg = p.cyan,
      bg = "NONE",
    })
  end,
})

local side_border = "🮇"
local dim_side_border = "%#Border#" .. side_border .. "%#None# "
local bottom_border = "▔"

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
  local win = vim.g.statusline_winid
  local line_number = vim.v.lnum
  local line_count = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win))
  local width = math.max(4, #tostring(line_count))

  if vim.v.virtnum < 0 then
    local on_last_line = line_number == line_count
      and line_number == vim.api.nvim_win_get_cursor(win)[1]
    local highlight = on_last_line and "EobBarActive" or "EobBar"
    return "%#" .. highlight .. "#" .. string.rep(bottom_border, 2 + width + 1) .. "%#None# "
  end
  if vim.v.virtnum > 0 then
    return "%#LineNr#%=" .. string.rep(" ", width - 1) .. "↳" .. dim_side_border
  end

  local highlight, border = "LineNr", dim_side_border
  if vim.v.relnum == 0 then
    local mode = vim.fn.mode()
    local visual = mode == "v" or mode == "V" or mode == "\22"
    highlight, border = "CursorLineNr", side_border .. (visual and "%#Normal# " or " ")
  end
  return "%s%=%#" .. highlight .. "#" .. string.format("%" .. width .. "d", line_number) .. border
end

local function is_edit_window(buf, win)
  return vim.fn.win_gettype(win) == "" and not vim.wo[win].diff and vim.bo[buf].buftype == ""
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "FileType", "WinEnter" }, {
  group = statuscolumn_group,
  callback = function(event)
    local buf = event.buf
    local win = vim.api.nvim_get_current_win()
    local edit = is_edit_window(buf, win)
    local opts = { win = win }

    vim.api.nvim_set_option_value("number", edit, opts)
    vim.api.nvim_set_option_value("relativenumber", edit, opts)
    vim.api.nvim_set_option_value("signcolumn", edit and "yes:1" or "no", opts)
    vim.api.nvim_set_option_value(
      "statuscolumn",
      edit and "%!v:lua.require('config.statuscolumn').render_normal_statuscolumn()" or "",
      opts
    )
    if edit then
      update_eob_bar(buf)
    end
  end,
})

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  group = statuscolumn_group,
  callback = function(event)
    update_eob_bar(event.buf)
  end,
})

return {
  render_normal_statuscolumn = render_normal_statuscolumn,
}
