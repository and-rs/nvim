local color = require("config.coloring")

local LIGHT_ADJUST = { yank = 1.7, visual = 1.74, diag = 1.8 }
local DARK_ADJUST = { yank = 0.3, visual = 0.3, diag = 0.2 }

local function setup_light_mode()
  color.set("NvimRed", { fg = "#590008" })
  color.set("NvimGreen", { fg = "#005523" })
  color.set("NvimYellow", { fg = "#6b5300" })
  color.set("NvimBlue", { fg = "#004c73" })
  color.set("NvimPink", { fg = "#470045" })
  color.set("NvimCyan", { fg = "#007373" })
  color.set("NvimTeal", { fg = "#005e5e" })
  color.set("NvimLime", { fg = "#3b5500" })
  color.set("NvimViolet", { fg = "#2b0059" })
  color.set("NvimFuchsia", { fg = "#59002b" })
  color.set("NvimGrey", { fg = "#4f5258" })
  color.set("NvimWhite", { fg = color.adjust_hex("#a2a5ac", 0.5) })
end

local function setup_dark_mode()
  color.set("NvimPink", { fg = "#ffcaff" })
  color.set("NvimBlue", { fg = "#a6dbff" })
  color.set("NvimGrey", { fg = "#79839c" })
  color.set("NvimWhite", { fg = "#e0e2ea" })
  color.set("NvimRed", { fg = "#ffc0b9" })
  color.set("NvimGreen", { fg = "#b3f6c0" })
  color.set("NvimYellow", { fg = "#fce094" })
  color.set("NvimCyan", { fg = "#8cf8f7" })
  color.set("NvimTeal", { fg = "#8cf8d2" })
  color.set("NvimLime", { fg = "#d9f6b3" })
  color.set("NvimViolet", { fg = "#d2b3f6" })
  color.set("NvimFuchsia", { fg = "#f6b3e0" })
end

local function setup_common()
  local is_light = vim.o.background == "light"
  local adjust = is_light and LIGHT_ADJUST or DARK_ADJUST

  color.set("Type", { link = "NvimPink" })
  color.set("Boolean", { link = "NvimPink" })
  color.set("Special", { link = "NvimPink" })
  color.set("Keyword", { link = "NvimBlue" })
  color.set("Statement", { link = "NvimBlue" })
  color.set("Comment", { link = "NvimGrey" })
  color.set("NonText", { link = "NvimGrey" })
  color.set("Variable", { link = "NvimGrey" })
  color.set("Operator", { link = "NvimGrey" })
  color.set("Delimiter", { link = "NvimGrey" })
  color.set("Identifier", { link = "NvimWhite" })
  color.set("Function", { fg = color.highlight("Function", "fg"), italic = true })

  color.set("CursorLine", { bg = "None" })
  color.set("TabKeySel", {
    fg = color.highlight("Normal", "bg"),
    bg = color.highlight("NvimBlue", "fg"),
    underline = true,
    bold = true,
  })
  color.set("TabLineSel", {
    fg = color.highlight("Normal", "bg"),
    bg = color.highlight("NvimBlue", "fg"),
    bold = true,
  })
  color.set("TabLine", { bg = color.highlight("NormalFloat", "bg") })
  color.set("TabKey", {
    bg = color.highlight("NormalFloat", "bg"),
    fg = color.highlight("NvimBlue", "fg"),
    bold = true,
  })
  color.set("TabLineFill", { bg = color.highlight("Normal", "bg") })
  color.set("Substitute", {
    bg = color.highlight("String", "fg"),
    fg = color.highlight("Normal", "bg"),
  })

  color.set("Select", {
    bg = color.highlight("Normal", "bg"),
  })
  color.set("YankHighlight", {
    bg = color.adjust_hex(color.highlight("NvimBlue", "fg"), adjust.yank),
  })
  color.set("Visual", {
    bg = color.adjust_hex(color.highlight("NvimGrey", "fg"), adjust.visual),
  })
  color.set("VisualNonText", {
    fg = color.adjust_hex(color.highlight("Normal", "fg"), adjust.yank),
    bg = color.highlight("Visual", "bg"),
  })

  color.set("IncSearch", {
    bg = color.highlight("Visual", "bg"),
    fg = color.highlight("String", "fg"),
    underline = true,
  })
  color.set("Search", {
    bg = color.highlight("Normal", "bg"),
    fg = color.highlight("Normal", "fg"),
    underline = true,
  })
  color.set("MatchParen", {
    bg = color.highlight("Visual", "bg"),
    fg = color.highlight("String", "fg"),
    bold = true,
    underline = true,
  })

  color.set("DiffAdd", { bg = "#c0e9da", fg = color.highlight("Normal", "fg") })
  color.set("DiffDelete", { bg = "#ff9999", fg = color.highlight("Normal", "fg") })

  color.set("DiagnosticUnnecessary", { underline = true })
  for name, diag_type in pairs({
    Info = "DiagnosticInfo",
    Hint = "DiagnosticHint",
    Warn = "DiagnosticWarn",
    Error = "DiagnosticError",
  }) do
    local diag_color = color.highlight(diag_type, "fg")
    if diag_color then
      color.set("DiagnosticVirtualText" .. name, {
        fg = diag_color,
        bg = color.adjust_hex(diag_color, adjust.diag),
      })
    end
  end
end

local function apply_theme()
  if vim.o.background == "dark" then
    setup_dark_mode()
  else
    setup_light_mode()
  end
  setup_common()
end

vim.api.nvim_create_autocmd({ "VimEnter", "OptionSet" }, {
  pattern = vim.o.background == "OptionSet" and "background" or "*",
  group = color.augroup,
  callback = apply_theme,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  group = color.augroup,
  callback = function()
    vim.highlight.on_yank({ higroup = "YankHighlight" })
  end,
})
