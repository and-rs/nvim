local color = require("config.coloring")
local theme = require("config.theme")

---@param specs table<string, vim.api.keyset.highlight>
local function apply_specs(specs)
  for group, spec in pairs(specs) do
    color.set(group, spec)
  end
end

local function apply()
  if not theme.sourced then
    return
  end

  local p = theme.palette
  local grey = color.adjust_hex(p.surface5, 0.3)

  ---@type table<string, vim.api.keyset.highlight>
  local specs = {
    DiagnosticUnnecessary = { underline = true },
    DiagnosticUnderlineError = { underline = false, undercurl = true },
    DiagnosticVirtualTextInfo = {
      fg = p.cyan,
      bg = color.adjust_hex(p.cyan, 0.2),
    },
    DiagnosticVirtualTextHint = {
      fg = p.cyan,
      bg = color.adjust_hex(p.cyan, 0.2),
    },
    DiagnosticVirtualTextWarn = {
      fg = p.yellow,
      bg = color.adjust_hex(p.yellow, 0.2),
    },
    DiagnosticVirtualTextError = {
      fg = p.red,
      bg = color.adjust_hex(p.red, 0.2),
    },

    TabKey = {
      fg = p.blue,
      bg = grey,
      underline = true,
    },
    TabLine = {
      fg = p.blue,
      bg = grey,
    },

    TabKeySel = {
      fg = grey,
      bg = p.blue,
      underline = true,
      bold = true,
    },
    TabLineSel = {
      fg = grey,
      bg = p.blue,
      bold = true,
    },

    YaziFloat = { link = "NormalFloat" },
    YaziFloatBorder = { link = "FloatBorder" },

    Substitute = { bg = p.green, fg = p.bg },
    Search = {
      bg = grey,
      fg = p.cyan,
      underline = true,
    },
    IncSearch = {
      bg = grey,
      fg = p.green,
      underline = true,
    },
    MatchParen = {
      bg = grey,
      fg = p.green,
      bold = true,
      underline = true,
    },

    MsgArea = {
      fg = p.cyan,
    },
    Pmenu = {
      fg = p.cyan,
      bg = p.bg,
    },
    PmenuSel = {
      fg = p.cyan,
      bg = p.bg,
      bold = true,
    },
    PmenuMatch = {
      fg = p.cyan,
      bg = p.bg,
      bold = true,
    },

    ["@markup.raw.markdown_inline"] = {
      bg = grey,
    },

    Select = { bg = p.bg },
    YankHighlight = { bg = color.adjust_hex(p.green, 0.5) },
    VisualNonText = {
      fg = color.adjust_hex(p.selection, 1.1),
      bg = color.get("Visual").bg,
    },
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
    vim.highlight.on_yank({
      higroup = theme.sourced and "YankHighlight" or "IncSearch",
    })
  end,
})
