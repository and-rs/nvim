local color = require("config.coloring")

local COLOR_PRIMARY = "NvimBlue"
local COLOR_SECONDARY = "NvimGrey"
local COLOR_BACKGROUND = "NormalFloat"

local COMPONENT_SIGN_NORMAL = "%s"
local COMPONENT_SIGN_FLOAT = ""
local COMPONENT_ALIGNMENT = "%#LineNr#%="
local HIGHLIGHT_CURRENT_LINE = "%#CursorLineNr#"
local HIGHLIGHT_LINE_NUMBER = "%#LineNr#"
local COMPONENT_BORDER_CURRENT = "%#CursorLineNr#▕%#Normal# "
local COMPONENT_BORDER_NORMAL = "%#SignColumn#▕%#Normal# "

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = color.augroup,
  pattern = "*",
  callback = function()
    color.set("LineNr", {
      fg = color.get(COLOR_SECONDARY, "fg"),
      bg = color.get(COLOR_BACKGROUND, "bg"),
    })
    color.set("CursorLineNr", {
      fg = color.get(COLOR_PRIMARY, "fg"),
      bg = color.get(COLOR_BACKGROUND, "bg"),
      bold = true,
    })
    color.set("SignColumn", {
      fg = color.adjust_hex(color.get(COLOR_SECONDARY, "fg"), 0.3),
      bg = color.get(COLOR_BACKGROUND, "bg"),
    })

    for _, severity in ipairs({ "Ok", "Hint", "Warn", "Info", "Error" }) do
      color.set("DiagnosticSign" .. severity, {
        fg = color.get("Diagnostic" .. severity, "fg"),
        bg = color.get(COLOR_BACKGROUND, "bg"),
      })
    end

    local git_status_map = {
      Add = "Added",
      Change = "Changed",
      Delete = "Removed",
      Untracked = "Added",
    }

    for git_status, highlight_group in pairs(git_status_map) do
      color.set("GitSigns" .. git_status, {
        fg = color.get(highlight_group, "fg"),
        bg = color.get(COLOR_BACKGROUND, "bg"),
      })
    end
  end,
})

--- Renders the statuscolumn layout optimized for standard Neovim windows
--- @return string Statuscolumn formatted string
local function render_normal_statuscolumn()
  local relative_number = vim.v.relnum

  if vim.v.virtnum ~= 0 then
    return COMPONENT_SIGN_NORMAL
      .. COMPONENT_ALIGNMENT
      .. "    "
      .. (relative_number == 0 and COMPONENT_BORDER_CURRENT or COMPONENT_BORDER_NORMAL)
  end

  local line_number_string = string.format("%4d", vim.v.lnum)

  if relative_number == 0 then
    return COMPONENT_SIGN_NORMAL
      .. COMPONENT_ALIGNMENT
      .. HIGHLIGHT_CURRENT_LINE
      .. line_number_string
      .. COMPONENT_BORDER_CURRENT
  end

  return COMPONENT_SIGN_NORMAL
    .. COMPONENT_ALIGNMENT
    .. HIGHLIGHT_LINE_NUMBER
    .. line_number_string
    .. COMPONENT_BORDER_NORMAL
end

--- Renders the statuscolumn layout optimized for floating windows
--- @return string Statuscolumn formatted string
local function render_float_statuscolumn()
  local relative_number = vim.v.relnum

  if vim.v.virtnum ~= 0 then
    return COMPONENT_SIGN_FLOAT
      .. COMPONENT_ALIGNMENT
      .. "      "
      .. (relative_number == 0 and COMPONENT_BORDER_CURRENT or COMPONENT_BORDER_NORMAL)
  end

  local line_number_string = string.format("%6d", vim.v.lnum)

  if relative_number == 0 then
    return COMPONENT_SIGN_FLOAT
      .. COMPONENT_ALIGNMENT
      .. HIGHLIGHT_CURRENT_LINE
      .. line_number_string
      .. COMPONENT_BORDER_CURRENT
  end

  return COMPONENT_SIGN_FLOAT
    .. COMPONENT_ALIGNMENT
    .. HIGHLIGHT_LINE_NUMBER
    .. line_number_string
    .. COMPONENT_BORDER_NORMAL
end

local statuscolumn_group = vim.api.nvim_create_augroup("StatusColumn", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group = statuscolumn_group,
  callback = function(event)
    local buffer_number = event.buf
    local is_valid_buffer = vim.bo[buffer_number].buftype == ""
      and vim.bo[buffer_number].filetype ~= ""

    if not is_valid_buffer then
      vim.opt_local.relativenumber = false
      vim.opt_local.numberwidth = 1
      vim.opt_local.signcolumn = "no"
      vim.opt_local.statuscolumn = "%s"
      return
    end

    local is_floating_window = vim.api.nvim_win_get_config(0).relative ~= ""

    vim.opt_local.relativenumber = true
    vim.opt_local.signcolumn = "yes:1"

    if is_floating_window then
      vim.opt_local.statuscolumn =
        "%!v:lua.require('config.statuscolumn').render_float_statuscolumn()"
    else
      vim.opt_local.statuscolumn =
        "%!v:lua.require('config.statuscolumn').render_normal_statuscolumn()"
    end
  end,
})

return {
  render_normal_statuscolumn = render_normal_statuscolumn,
  render_float_statuscolumn = render_float_statuscolumn,
}
