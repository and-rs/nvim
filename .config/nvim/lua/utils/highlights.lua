local coloring = require("utils.coloring")

local function set_hl(highlight, options)
  vim.api.nvim_set_hl(0, highlight, options)
end

vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  group = coloring.augroup,
  callback = function()
    set_hl("NvimPink", { fg = "#ffcaff" })
    set_hl("NvimBlue", { fg = "#a6dbff" })
    set_hl("NvimGrey", { fg = "#79839c" })
    set_hl("NvimWhite", { fg = "#e0e2ea" })

    set_hl("Type", { link = "NvimPink" })
    set_hl("Boolean", { link = "NvimPink" })
    set_hl("Special", { link = "NvimPink" })
    set_hl("Keyword", { link = "NvimBlue" })
    set_hl("Statement", { link = "NvimBlue" })
    set_hl("Comment", { link = "NvimGrey" })
    set_hl("NonText", { link = "NvimGrey" })
    set_hl("Variable", { link = "NvimGrey" })
    set_hl("Operator", { link = "NvimGrey" })
    set_hl("Delimiter", { link = "NvimGrey" })
    set_hl("Identifier", { link = "NvimWhite" })

    set_hl("Substitute", {
      bg = coloring.highlight("String", "fg"),
      fg = coloring.highlight("Normal", "bg"),
    })
    set_hl("Visual", {
      bg = coloring.darken_hex(coloring.highlight("NvimGrey", "fg"), 0.35),
    })
    set_hl("IncSearch", {
      bg = coloring.highlight("Visual", "bg"),
      fg = coloring.highlight("String", "fg"),
      underline = true,
    })
    set_hl("Search", {
      bg = coloring.highlight("Normal", "bg"),
      fg = coloring.highlight("Normal", "fg"),
      underline = true,
    })
    set_hl("MatchParen", {
      bg = coloring.highlight("Visual", "bg"),
      fg = coloring.highlight("String", "fg"),
      bold = true,
      underline = true,
    })

    local hint_color = coloring.highlight("DiagnosticHint", "fg")
    local warn_color = coloring.highlight("DiagnosticWarn", "fg")
    local error_color = coloring.highlight("DiagnosticError", "fg")

    if hint_color then
      set_hl("DiagnosticVirtualTextHint", {
        fg = hint_color,
        bg = coloring.darken_hex(hint_color),
      })
    end
    if warn_color then
      set_hl("DiagnosticVirtualTextWarn", {
        fg = warn_color,
        bg = coloring.darken_hex(warn_color),
      })
    end
    if error_color then
      set_hl("DiagnosticVirtualTextError", {
        fg = error_color,
        bg = coloring.darken_hex(error_color),
      })
    end

    set_hl("DiagnosticUnnecessary", { underline = true })

    set_hl("TreesitterContext", { bg = coloring.highlight("Normal", "bg") })
    set_hl("TreesitterContextLineNumberBottom", { link = "LineNr" })
    set_hl("TreesitterContextBottom", {
      bg = coloring.highlight("Normal", "bg"),
      sp = coloring.highlight("NvimGrey", "fg"),
      underline = true,
    })

    set_hl("FzfLuaBackdrop", { link = "NormalSB" })
    set_hl("MasonBackdrop", { link = "NormalSB" })
    set_hl("YaziFloatBorder", { link = "NormalFloat" })
    set_hl("YaziFloat", { bg = coloring.highlight("NormalFloat", "bg") })
    set_hl("WhichKeyTitle", { bg = coloring.highlight("NormalFloat", "bg") })
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  group = coloring.augroup,
  callback = function()
    vim.highlight.on_yank({ higroup = "Substitute" })
  end,
})
