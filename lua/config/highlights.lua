local color = require("config.coloring")

local function setup_light_mode()
  color.set("NvimPink", { fg = "#470045" })
  color.set("NvimBlue", { fg = "#004c73" })
  color.set("NvimGrey", { fg = "#4f5258" })
  color.set("NvimWhite", { fg = color.darken_hex("#a2a5ac", 0.5) })
end

local function setup_dark_mode()
  color.set("NvimPink", { fg = "#ffcaff" })
  color.set("NvimBlue", { fg = "#a6dbff" })
  color.set("NvimGrey", { fg = "#79839c" })
  color.set("NvimWhite", { fg = "#e0e2ea" })
end

local function setup_common()
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
  color.set("Function", {
    fg = color.highlight("Function", "fg"),
    italic = true,
  })

  color.set("CursorLine", { bg = "None" })
  color.set("TabKeySel", {
    fg = color.lighten_hex(color.highlight("NvimBlue", "fg"), 0.5),
    bg = color.darken_hex(color.highlight("NvimBlue", "fg"), 0.75),
    bold = true,
  })
  color.set("TabLineSel", {
    fg = color.lighten_hex(color.highlight("NvimBlue", "fg"), 0.5),
    bg = color.darken_hex(color.highlight("NvimBlue", "fg"), 0.75),
  })
  color.set("TabLine", {
    bg = color.highlight("NormalFloat", "bg"),
  })
  color.set("TabKey", {
    fg = color.highlight("NvimBlue", "fg"),
    bold = true,
  })
  color.set("TabLineFill", {
    bg = color.highlight("Normal", "bg"),
  })
  color.set("Substitute", {
    bg = color.highlight("String", "fg"),
    fg = color.highlight("Normal", "bg"),
  })

  local grey_fg = color.highlight("NvimGrey", "fg")
  local is_dark = vim.o.background == "dark"
  color.set("Visual", {
    bg = is_dark and color.darken_hex(grey_fg, 0.7) or color.lighten_hex(grey_fg, 0.75),
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

  local hint_color = color.highlight("DiagnosticHint", "fg")
  local warn_color = color.highlight("DiagnosticWarn", "fg")
  local error_color = color.highlight("DiagnosticError", "fg")
  color.set("DiagnosticUnnecessary", { underline = true })

  if hint_color then
    color.set("DiagnosticVirtualTextHint", {
      fg = hint_color,
      bg = is_dark and color.darken_hex(hint_color, 0.8) or color.lighten_hex(hint_color, 0.6),
    })
  end
  if warn_color then
    color.set("DiagnosticVirtualTextWarn", {
      fg = warn_color,
      bg = is_dark and color.darken_hex(warn_color, 0.8) or color.lighten_hex(warn_color, 0.6),
    })
  end
  if error_color then
    color.set("DiagnosticVirtualTextError", {
      bg = is_dark and color.darken_hex(error_color, 0.8) or color.lighten_hex(error_color, 0.6),
      fg = error_color,
    })
  end

  color.set("VisualNonText", {
    fg = is_dark and color.darken_hex(color.highlight("NvimGrey", "fg"), 0.5)
      or color.lighten_hex(color.highlight("NvimGrey", "fg"), 0.5),

    bg = color.highlight("Visual", "bg"),
  })

  color.set("FzfLuaBackdrop", { link = "NormalSB" })
  color.set("MasonBackdrop", { link = "NormalSB" })
  color.set("YaziFloatBorder", { link = "NormalFloat" })
  color.set("YaziFloat", { bg = color.highlight("NormalFloat", "bg") })
  color.set("WhichKeyTitle", { bg = color.highlight("NormalFloat", "bg") })
end

vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  group = color.augroup,
  callback = function()
    if vim.o.background == "dark" then
      setup_dark_mode()
    else
      setup_light_mode()
    end
    setup_common()
  end,
})

vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  group = color.augroup,
  callback = function()
    if vim.o.background == "dark" then
      setup_dark_mode()
    else
      setup_light_mode()
    end
    setup_common()
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  group = color.augroup,
  callback = function()
    vim.highlight.on_yank({ higroup = "Substitute" })
  end,
})
