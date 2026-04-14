local color = require("config.coloring")

color.set("WhichKeyTitle", { bg = color.get("NormalFloat", "bg") })
color.set("YaziFloatBorder", { link = "NormalFloat" })
color.set("YaziFloat", { bg = color.get("NormalFloat", "bg") })

local palettes = {
  light = {
    NvimRed = "#590008",
    NvimGreen = "#005523",
    NvimYellow = "#6b5300",
    NvimBlue = "#004c73",
    NvimPink = "#470045",
    NvimCyan = "#007373",
    NvimTeal = "#005e5e",
    NvimLime = "#3b5500",
    NvimViolet = "#2b0059",
    NvimFuchsia = "#59002b",
    NvimGrey = "#4f5258",
    NvimWhite = color.adjust_hex("#a2a5ac", 0.5),
  },
  dark = {
    NvimPink = "#ffcaff",
    NvimBlue = "#a6dbff",
    NvimGrey = "#79839c",
    NvimWhite = "#e0e2ea",
    NvimRed = "#ffc0b9",
    NvimGreen = "#b3f6c0",
    NvimYellow = "#fce094",
    NvimCyan = "#8cf8f7",
    NvimTeal = "#8cf8d2",
    NvimLime = "#d9f6b3",
    NvimViolet = "#d2b3f6",
    NvimFuchsia = "#f6b3e0",
  },
}

local adjust = {
  light = { yank = 1.7, visual = 1.74, diag = 1.8 },
  dark = { yank = 0.3, visual = 0.3, diag = 0.2 },
}

local links = {
  Type = "NvimPink",
  Boolean = "NvimPink",
  Special = "NvimPink",
  Statement = "NvimBlue",
  Comment = "NvimGrey",
  NonText = "NvimGrey",
  Variable = "NvimGrey",
  Operator = "NvimGrey",
  Delimiter = "NvimGrey",
  Identifier = "NvimWhite",
}

local diagnostics = {
  Info = "DiagnosticInfo",
  Hint = "DiagnosticHint",
  Warn = "DiagnosticWarn",
  Error = "DiagnosticError",
}

local function apply()
  local mode = vim.o.background == "light" and "light" or "dark"
  local a = adjust[mode]

  for group, fg in pairs(palettes[mode]) do
    color.set(group, { fg = fg })
  end

  for group, link in pairs(links) do
    color.set(group, { link = link })
  end

  local normal_bg = color.get("Normal", "bg")
  local normal_fg = color.get("Normal", "fg")
  local float_bg = color.get("NormalFloat", "bg")
  local blue = color.get("NvimBlue", "fg")
  local grey = color.get("NvimGrey", "fg")
  local string_fg = color.get("String", "fg")
  local visual_bg = color.adjust_hex(grey, a.visual)

  if mode == "light" then
    color.set("DiffAdd", { bg = "#c0e9da", fg = normal_fg })
    color.set("DiffDelete", { bg = "#ff9999", fg = normal_fg })
    color.set("DiffTextAdd", { bg = "#a3dcc1", fg = normal_fg, bold = true })
  else
    color.set("DiffAdd", { bg = "#163326", fg = normal_fg })
    color.set("DiffDelete", { bg = "#44262b", fg = normal_fg })
    color.set("DiffTextAdd", { bg = "#25593e", fg = normal_fg, bold = true })
  end

  color.set("Function", { italic = true })
  color.set("Keyword", {
    bg = color.darken_hex(color.get("NvimBlue", "fg"), 0.85),
    fg = color.get("NvimBlue", "fg"),
  })
  color.set("CursorLine", { bg = "None" })
  color.set("DiagnosticUnnecessary", { underline = true })

  color.set("TabKeySel", {
    fg = normal_bg,
    bg = blue,
    underline = true,
    bold = true,
  })
  color.set("TabLineSel", {
    fg = normal_bg,
    bg = blue,
    bold = true,
  })
  color.set("TabLine", { bg = float_bg })
  color.set("TabKey", {
    bg = float_bg,
    fg = blue,
    bold = true,
  })
  color.set("TabLineFill", { bg = normal_bg })

  color.set("Substitute", {
    bg = string_fg,
    fg = normal_bg,
  })

  color.set("Select", { bg = normal_bg })
  color.set("YankHighlight", {
    bg = color.adjust_hex(blue, a.yank),
  })
  color.set("Visual", { bg = visual_bg })
  color.set("VisualNonText", {
    fg = color.adjust_hex(normal_fg, a.yank),
    bg = visual_bg,
  })

  color.set("IncSearch", {
    bg = visual_bg,
    fg = string_fg,
    underline = true,
  })
  color.set("Search", {
    bg = normal_bg,
    fg = normal_fg,
    underline = true,
  })
  color.set("MatchParen", {
    bg = visual_bg,
    fg = string_fg,
    bold = true,
    underline = true,
  })

  for suffix, source in pairs(diagnostics) do
    local fg = color.get(source, "fg")
    if fg then
      color.set("DiagnosticVirtualText" .. suffix, {
        fg = fg,
        bg = color.adjust_hex(fg, a.diag),
      })
    end
  end
end

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = color.augroup,
  callback = apply,
})

vim.api.nvim_create_autocmd("OptionSet", {
  group = color.augroup,
  pattern = "background",
  callback = apply,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = color.augroup,
  callback = function()
    vim.highlight.on_yank({ higroup = "YankHighlight" })
  end,
})
