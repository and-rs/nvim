local color = require("config.coloring")
local theme = require("config.theme")

---@param specs table<string, vim.api.keyset.highlight>
local function apply_specs(specs)
  for group, spec in pairs(specs) do
    color.set(group, spec)
  end
end

local p = theme.palette

local function apply()
  if not theme.sourced then
    return
  end

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
      bg = p.surface2,
      underline = true,
    },
    TabLine = {
      fg = p.blue,
      bg = p.surface2,
    },

    TabKeySel = {
      fg = p.surface2,
      bg = p.blue,
      underline = true,
      bold = true,
    },
    TabLineSel = {
      fg = p.surface2,
      bg = p.blue,
      bold = true,
    },

    YaziFloat = { link = "NormalFloat" },
    YaziFloatBorder = { link = "FloatBorder" },

    Substitute = { bg = p.green, fg = p.bg },
    Search = {
      bg = p.blue,
      fg = p.bg,
      underline = true,
    },
    IncSearch = {
      bg = p.magenta,
      fg = p.bg,
      bold = true,
      underline = true,
    },
    MatchParen = {
      bg = p.blue,
      fg = p.bg,
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
      bg = p.surface2,
    },

    EndOfBuffer = { bg = "" },
    Select = { bg = p.bg },
    YankHighlight = {
      fg = p.surface2,
      bg = color.adjust_hex(p.cyan, 0.8),
    },
    GitsignsCurrentLineBlame = { fg = p.surface4 },

    -- remove to disable transparency
    NormalNC = {
      fg = p.white,
      bg = "",
    },
    NormalFloat = {
      fg = p.white,
      bg = p.surface1,
    },
    NormalSB = {
      fg = p.white,
      bg = "",
    },
    Normal = {
      fg = p.white,
      bg = "",
    },
    -- transparency

    Whitespace = {
      fg = p.surface3,
    },

    Visual = {
      fg = color.adjust_hex(p.blue, 1.1),
      bg = color.get("Visual").bg,
      bold = true
    },
    VisualNonText = {
      fg = color.adjust_hex(p.selection, 1.2),
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
