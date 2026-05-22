local color = require("config.coloring")
local palette = require("config.palette")

---@param specs table<string, vim.api.keyset.highlight>
local function apply_specs(specs)
  for group, spec in pairs(specs) do
    color.set(group, spec)
  end
end

local function apply()
  palette.apply()

  ---@type table<string, vim.api.keyset.highlight>
  local specs = {
    DiagnosticUnnecessary = { underline = true },
    DiagnosticUnderlineError = { underline = false, undercurl = true },
    DiagnosticVirtualTextInfo = {
      fg = color.get("DiagnosticInfo").fg or color.get("NvimBlue").fg,
      bg = color.adjust_hex(color.get("DiagnosticInfo").fg or color.get("NvimBlue").fg, 0.2),
    },
    DiagnosticVirtualTextHint = {
      fg = color.get("DiagnosticHint").fg or color.get("NvimBlue").fg,
      bg = color.adjust_hex(color.get("DiagnosticHint").fg or color.get("NvimBlue").fg, 0.2),
    },
    DiagnosticVirtualTextWarn = {
      fg = color.get("DiagnosticWarn").fg or color.get("NvimYellow").fg,
      bg = color.adjust_hex(color.get("DiagnosticWarn").fg or color.get("NvimYellow").fg, 0.2),
    },
    DiagnosticVirtualTextError = {
      fg = color.get("DiagnosticError").fg or color.get("NvimRed").fg,
      bg = color.adjust_hex(color.get("DiagnosticError").fg or color.get("NvimRed").fg, 0.2),
    },

    TabKey = {
      fg = color.get("NvimBlue").fg,
      bg = color.adjust_hex(color.get("NvimGrey").fg, 0.3),
      underline = true
    },
    TabLine = {
      fg = color.get("NvimBlue").fg,
      bg = color.adjust_hex(color.get("NvimGrey").fg, 0.3)
    },

    TabKeySel = {
      fg = color.adjust_hex(color.get("NvimGrey").fg, 0.3),
      bg = color.get("NvimBlue").fg,
      underline = true,
      bold = true,
    },
    TabLineSel = {
      fg = color.adjust_hex(color.get("NvimGrey").fg, 0.3),
      bg = color.get("NvimBlue").fg,
      bold = true
    },

    YaziFloat = { link = "NormalFloat" },
    YaziFloatBorder = { link = "FloatBorder" },

    Substitute = { bg = color.get("NvimGreen").fg, fg = color.get("Normal").bg },
    IncSearch = {
      bg = color.adjust_hex(color.get("NvimGrey").fg, 0.3),
      fg = color.get("NvimGreen").fg,
      underline = true,
    },
    MatchParen = {
      bg = color.adjust_hex(color.get("NvimGrey").fg, 0.3),
      fg = color.get("NvimGreen").fg,
      bold = true,
      underline = true,
    },

    Select = { bg = color.get("Normal").bg },
    YankHighlight = { bg = color.adjust_hex(color.get("NvimYellow").fg, 0.5) },
    VisualNonText = {
      fg = color.adjust_hex(color.get("Visual").bg, 1.1),
      bg = color.get("Visual").bg,
    },
    Search = { bg = color.get("Normal").bg, fg = color.get("Normal").fg, underline = true },
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
