local color = require("config.coloring")
local palette = require("config.palette")

local adjust = {
  light = { yank = 1.7, visual = 1.74, diag = 1.8 },
  dark = { yank = 0.5, visual = 0.3, diag = 0.2 },
}

---@param specs table<string, vim.api.keyset.highlight>
local function apply_specs(specs)
  for group, spec in pairs(specs) do
    color.set(group, spec)
  end
end

local function apply()
  palette.apply()

  local mode = vim.o.background == "light" and "light" or "dark"
  local a = adjust[mode]

  local normal_bg = color.get("Normal").bg
  local normal_fg = color.get("Normal").fg
  local blue = color.get("NvimBlue").fg
  local grey = color.get("NvimGrey").fg
  local yellow = color.get("NvimYellow").fg
  local green = color.get("NvimGreen").fg
  local visual_bg = color.adjust_hex(grey, a.visual)
  local visual_bg_native = color.get("Visual").bg
  local diagnostic_info = color.get("DiagnosticInfo").fg or blue
  local diagnostic_hint = color.get("DiagnosticHint").fg or blue
  local diagnostic_warn = color.get("DiagnosticWarn").fg or yellow
  local diagnostic_error = color.get("DiagnosticError").fg or color.get("NvimRed").fg

  ---@type table<string, vim.api.keyset.highlight>
  local specs = {
    DiagnosticUnnecessary = { underline = true },
    DiagnosticUnderlineError = { underline = false, undercurl = true },
    DiagnosticVirtualTextInfo = {
      fg = diagnostic_info,
      bg = color.adjust_hex(diagnostic_info, a.diag),
    },
    DiagnosticVirtualTextHint = {
      fg = diagnostic_hint,
      bg = color.adjust_hex(diagnostic_hint, a.diag),
    },
    DiagnosticVirtualTextWarn = {
      fg = diagnostic_warn,
      bg = color.adjust_hex(diagnostic_warn, a.diag),
    },
    DiagnosticVirtualTextError = {
      fg = diagnostic_error,
      bg = color.adjust_hex(diagnostic_error, a.diag),
    },

    TabKey = { fg = blue, bg = visual_bg, underline = true },
    TabLine = { fg = blue, bg = visual_bg },

    TabKeySel = { fg = visual_bg, bg = blue, underline = true, bold = true },
    TabLineSel = { fg = visual_bg, bg = blue, bold = true },

    YaziFloat = { link = "NormalFloat" },
    YaziFloatBorder = { link = "FloatBorder" },

    Substitute = { bg = green, fg = normal_bg },
    IncSearch = { bg = visual_bg, fg = green, underline = true },
    MatchParen = { bg = visual_bg, fg = green, bold = true, underline = true },

    Select = { bg = normal_bg },
    YankHighlight = { bg = color.adjust_hex(blue, a.yank) },
    VisualNonText = { fg = color.adjust_hex(normal_fg, a.yank), bg = visual_bg_native },
    Search = { bg = normal_bg, fg = normal_fg, underline = true },
  }

  apply_specs(specs)
end

apply()

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
