local color = require("config.coloring")

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = color.augroup,
  pattern = "*",
  callback = function()
    local primary = color.highlight("NvimBlue", "fg")
    local secondary = color.highlight("NvimGrey", "fg")
    local background = color.highlight("StatusLine", "bg")
    local col_bg = color.highlight("NormalFloat", "bg")

    color.set("ColumnBase0", { fg = secondary, bg = col_bg })
    color.set("ColumnBase1", { fg = background, bg = col_bg })
    color.set("Column0", { fg = primary, bg = col_bg, bold = true })
    color.set("Column1", { fg = color.adjust_hex(secondary, 1.3), bg = col_bg })
    color.set("SignColumn", { fg = color.adjust_hex(secondary, 0.3), bg = col_bg })

    for _, type in ipairs({ "Ok", "Hint", "Warn", "Info", "Error" }) do
      color.set("DiagnosticSign" .. type, {
        fg = color.highlight("Diagnostic" .. type, "fg"),
        bg = col_bg,
      })
    end

    local git_map = {
      Add = "Added",
      Change = "Changed",
      Delete = "Removed",
      Untracked = "Added",
    }
    for sign, hl in pairs(git_map) do
      color.set("GitSigns" .. sign, {
        fg = color.highlight(hl, "fg"),
        bg = col_bg,
      })
    end
  end,
})

--- Render the line number component
--- @param width integer The width of the number column (padding)
--- @return string
local function component_linenr(width)
  local gap = "%#ColumnBase0#%="
  if vim.v.virtnum ~= 0 then
    return "%#ColumnBase0#" .. string.rep(" ", width)
  end
  local lnum = string.format("%" .. width .. "d", vim.v.lnum)
  if vim.v.relnum == 1 then
    return gap .. "%#Column1#" .. lnum
  end
  if vim.v.relnum == 0 then
    return gap .. "%#Column0#" .. lnum
  end
  return gap .. "%#ColumnBase0#" .. lnum
end

--- Render the right-side border component
--- @return string
local function component_border()
  local char = "▕"
  if vim.v.relnum == 0 then
    return "%#Column0#" .. char .. "%#None# "
  end
  return "%#SignColumn#" .. char .. "%#None# "
end

local function bootstrap()
  local is_float = vim.api.nvim_win_get_config(0).relative ~= ""

  -- Configuration based on window type
  -- Float: 6 chars wide, no sign column
  -- Normal: 4 chars wide, includes sign column (%s)
  local width = is_float and 6 or 4
  local signs = is_float and "" or "%s"

  return signs .. component_linenr(width) .. component_border()
end

local group = vim.api.nvim_create_augroup("StatusColumn", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group = group,
  callback = function(ev)
    local bufnr = ev.buf
    local is_eligible = vim.bo[bufnr].buftype == "" and vim.bo[bufnr].filetype ~= ""

    if is_eligible then
      vim.opt_local.relativenumber = true
      vim.opt_local.statuscolumn = "%!v:lua.require('config.statuscolumn').bootstrap()"
      vim.opt_local.signcolumn = "yes:1"
    else
      vim.opt_local.relativenumber = false
      vim.opt_local.numberwidth = 1
      vim.opt_local.signcolumn = "no"
      vim.opt_local.statuscolumn = "%s"
    end
  end,
})

return {
  bootstrap = bootstrap,
}
