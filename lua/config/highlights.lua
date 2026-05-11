local color = require("config.coloring")

local adjust = {
  light = { yank = 1.7, visual = 1.74, diag = 1.8 },
  dark = { yank = 0.5, visual = 0.3, diag = 0.2 },
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

  local normal_bg = color.get("Normal", "bg")
  local normal_fg = color.get("Normal", "fg")
  local blue = color.get("Function", "fg")
  local grey = color.get("Comment", "fg")
  local string_fg = color.get("String", "fg") or normal_fg
  local visual_bg = color.adjust_hex(grey, a.visual)

  color.set("DiagnosticUnnecessary", { underline = true })
  color.set("DiagnosticUnderlineError", { underline = false, undercurl = true })

  color.set("TabKeySel", { fg = visual_bg, bg = blue, underline = true, bold = true })
  color.set("TabLineSel", { fg = visual_bg, bg = blue, bold = true })
  color.set("TabKey", { fg = blue, bold = true })

  color.set("FinderSel", { bg = color.get("Folded", "bg"), fg = normal_fg, bold = true })
  color.set("FinderMatch", { bg = color.get("Special", "fg"), fg = color.get("Folded", "bg"), bold = true })

  color.set("YaziFloatBorder", { link = "Normal" })

  color.set("Substitute", { bg = string_fg, fg = normal_bg })
  color.set("Select", { bg = normal_bg })

  color.set("YankHighlight", { bg = color.adjust_hex(blue, a.yank) })
  color.set("VisualNonText", { fg = color.adjust_hex(normal_fg, a.yank), bg = color.get("Visual", "bg") })

  color.set("IncSearch", { bg = visual_bg, fg = string_fg, underline = true })
  color.set("Search", { bg = normal_bg, fg = normal_fg, underline = true })
  color.set("MatchParen", { bg = visual_bg, fg = string_fg, bold = true, underline = true })

  for suffix, source in pairs(diagnostics) do
    local fg = color.get(source, "fg")
    if fg then
      color.set("DiagnosticVirtualText" .. suffix, { fg = fg, bg = color.adjust_hex(fg, a.diag) })
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
