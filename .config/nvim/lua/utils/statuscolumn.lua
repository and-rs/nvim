local coloring = require("utils.coloring")

local function set_hl(highlight, options)
  vim.api.nvim_set_hl(0, highlight, options)
end

local function gradient_two_steps(start_hex, end_hex)
  coloring.validate_hex(start_hex)
  coloring.validate_hex(end_hex)

  local start_r, start_g, start_b = coloring.hex_to_rgb(start_hex)
  local end_r, end_g, end_b = coloring.hex_to_rgb(end_hex)

  local factor1 = 0.6
  local factor2 = 0.8

  local color1 = coloring.rgb_to_hex(
    math.floor(start_r + (end_r - start_r) * factor1),
    math.floor(start_g + (end_g - start_g) * factor1),
    math.floor(start_b + (end_b - start_b) * factor1)
  )

  local color2 = coloring.rgb_to_hex(
    math.floor(start_r + (end_r - start_r) * factor2),
    math.floor(start_g + (end_g - start_g) * factor2),
    math.floor(start_b + (end_b - start_b) * factor2)
  )

  return {
    dark = color1,
    light = color2,
  }
end

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = coloring.augroup,
  pattern = "*",
  callback = function()
    local primary = coloring.highlight("NvimBlue", "fg")
    local secondary = coloring.highlight("NvimGrey", "fg")
    local background = coloring.highlight("StatusLine", "bg")
    local column_background = coloring.highlight("NormalFloat", "bg")

    local numbers = gradient_two_steps(primary, secondary)

    set_hl("ColumnBackground", { fg = coloring.adjust_hex(secondary, 0.3), bg = column_background })
    set_hl("ColumnBase0", { fg = secondary, bg = column_background })
    set_hl("ColumnBase1", { fg = background, bg = column_background })
    set_hl("Column0", { fg = primary, bg = column_background, bold = true })
    set_hl("Column1", { fg = numbers.dark, bg = column_background })
    set_hl("Column2", { fg = numbers.light, bg = column_background })

    set_hl("SignColumn", { bg = column_background })

    set_hl("DiagnosticSignOk", {
      fg = coloring.highlight("DiagnosticOk", "fg"),
      bg = column_background,
    })
    set_hl("DiagnosticSignHint", {
      fg = coloring.highlight("DiagnosticHint", "fg"),
      bg = column_background,
    })
    set_hl("DiagnosticSignWarn", {
      fg = coloring.highlight("DiagnosticWarn", "fg"),
      bg = column_background,
    })
    set_hl("DiagnosticSignInfo", {
      fg = coloring.highlight("DiagnosticInfo", "fg"),
      bg = column_background,
    })
    set_hl("DiagnosticSignError", {
      fg = coloring.highlight("DiagnosticError", "fg"),
      bg = column_background,
    })

    set_hl("GitSignsAdd", { fg = coloring.highlight("Added", "fg"), bg = column_background })
    set_hl("GitSignsUntracked", { fg = coloring.highlight("Added", "fg"), bg = column_background })
    set_hl("GitSignsChange", { fg = coloring.highlight("Changed", "fg"), bg = column_background })
    set_hl("GitSignsDelete", { fg = coloring.highlight("Removed", "fg"), bg = column_background })
  end,
})

local function number()
  local gap = "%#ColumnBase0#%="
  local linenumber = string.format("%4d", vim.v.lnum)

  if vim.v.virtnum ~= 0 then
    return "%#ColumnBase0#    "
  end

  if vim.v.relnum == 2 then
    return gap .. "%#Column2#" .. linenumber
  end
  if vim.v.relnum == 1 then
    return gap .. "%#Column1#" .. linenumber
  end
  if vim.v.relnum == 0 then
    return gap .. "%#Column0#" .. linenumber
  end
  return gap .. "%#ColumnBase0#" .. linenumber
end

local function border()
  local character = "🮇"

  if vim.v.relnum == 0 then
    return "%#Column0#" .. character .. "%#None# "
  end

  return "%#ColumnBackground#" .. character .. "%#None# "
end

local function bootstrap()
  local result = ""
  result = number() .. border()
  return "%s" .. result
end

local group = vim.api.nvim_create_augroup("StatusColumn", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group = group,
  callback = function(ev)
    local bufnr = ev.buf
    if vim.bo[bufnr].buftype == "" and vim.bo[bufnr].filetype ~= "" then
      vim.opt.relativenumber = true
      vim.opt.statuscolumn = "%!v:lua.require('utils.statuscolumn').bootstrap()"
      vim.opt.signcolumn = "yes:1"
    else
      vim.opt.relativenumber = false
      vim.opt.numberwidth = 1
      vim.opt.signcolumn = "no"
      vim.opt.statuscolumn = "%s"
    end
  end,
})

return {
  bootstrap = bootstrap,
}
