local color = require("config.coloring")

vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  group = color.augroup,
  callback = function()
    color.set("NvimPink", { fg = "#ffcaff" })
    color.set("NvimBlue", { fg = "#a6dbff" })
    color.set("NvimGrey", { fg = "#79839c" })
    color.set("NvimWhite", { fg = "#e0e2ea" })

    -- Syntax
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

    -- Matching UI
    color.set("CursorLine", {
      bg = "None",
    })
    color.set("Substitute", {
      bg = color.highlight("String", "fg"),
      fg = color.highlight("Normal", "bg"),
    })
    color.set("Visual", {
      bg = color.darken_hex(color.highlight("NvimGrey", "fg"), 0.35),
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

    -- Diagnostics
    local hint_color = color.highlight("DiagnosticHint", "fg")
    local warn_color = color.highlight("DiagnosticWarn", "fg")
    local error_color = color.highlight("DiagnosticError", "fg")
    color.set("DiagnosticUnnecessary", { underline = true })

    if hint_color then
      color.set("DiagnosticVirtualTextHint", {
        fg = hint_color,
        bg = color.darken_hex(hint_color),
      })
    end
    if warn_color then
      color.set("DiagnosticVirtualTextWarn", {
        fg = warn_color,
        bg = color.darken_hex(warn_color),
      })
    end
    if error_color then
      color.set("DiagnosticVirtualTextError", {
        fg = error_color,
        bg = color.darken_hex(error_color),
      })
    end

    -- plugins
    color.set("FzfLuaBackdrop", { link = "NormalSB" })
    color.set("MasonBackdrop", { link = "NormalSB" })
    color.set("YaziFloatBorder", { link = "NormalFloat" })
    color.set("YaziFloat", { bg = color.highlight("NormalFloat", "bg") })
    color.set("WhichKeyTitle", { bg = color.highlight("NormalFloat", "bg") })
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  group = color.augroup,
  callback = function()
    vim.highlight.on_yank({ higroup = "Substitute" })
  end,
})
