---returns the specific hex code from a selected highlight
---@param name string
---@param option string
---@return string | nil
function Get_hl_hex(name, option)
  if type(name) ~= "string" or (option ~= "fg" and option ~= "bg") then
    error("Invalid arguments. Usage: highlight(name: string, option: 'fg' | 'bg')")
  end
  local hl = vim.api.nvim_get_hl(0, { name = name })
  local color = hl[option]
  if not color then
    print("No " .. option .. " color found for highlight group: " .. name)
    return nil
  end
  local hex_color = string.format("#%06x", color)
  return hex_color
end

local function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber("0x" .. hex:sub(1, 2)),
    tonumber("0x" .. hex:sub(3, 4)),
    tonumber("0x" .. hex:sub(5, 6))
end

local function rgb_to_hex(r, g, b)
  return string.format("#%02x%02x%02x", r, g, b)
end

---darkens a hex value, with a factor of 0(black) to 1(unchanged)
---@param hex string | nil
---@param factor number | nil
---@return string | nil
function Darken_hex(hex, factor)
  if hex == nil then
    error("Nil value passed as hex, verify hex source")
    return
  end
  factor = factor or 0.15
  if factor > 1 or factor < 0 then
    factor = 0.15
    warn("Can't darken hex values with a factor higher than 1 or less than 0, defaulting to 0.15")
  end
  local r, g, b = hex_to_rgb(hex)
  local color = rgb_to_hex(math.floor(r * factor), math.floor(g * factor), math.floor(b * factor))
  return color
end

---shorter function call
---@param highlight string
---@param options table
local function set_hl(highlight, options)
  vim.api.nvim_set_hl(0, highlight, options)
end

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  group = vim.api.nvim_create_augroup("Color", {}),
  pattern = "*",
  callback = function()
    set_hl("Substitute", { bg = Get_hl_hex("String", "fg"), fg = Get_hl_hex("Normal", "bg") })
    set_hl("DiagnosticUnnecessary", { underline = true })
    set_hl("WinSeparator", { link = "FloatBorder" })

    set_hl("YaziFloatBorder", { link = "Conceal" })
    set_hl("FlashLabel", { fg = Get_hl_hex("Normal", "bg"), bg = Get_hl_hex("Normal", "fg") })

    -- light theme tweaks
    set_hl("FzfLuaBackdrop", { link = "NormalSB" })
    set_hl("MasonBackdrop", { link = "NormalSB" })
    set_hl("FloatShadow", { link = "NormalSB" })
    set_hl("FloatShadowThrough", { link = "NormalSB" })
    set_hl("FzfLuaLiveSym", { link = "Normal" })
    set_hl("FzfLuaLivePrompt", { link = "Normal" })

    -- [NOTE] highlight tweaks for default theme
    -- local hint_color = Get_hl_hex("DiagnosticHint", "fg")
    -- local warn_color = Get_hl_hex("DiagnosticWarn", "fg")
    -- local error_color = Get_hl_hex("DiagnosticError", "fg")
    -- set_hl("DiagnosticVirtualTextHint", { fg = hint_color, bg = Darken_hex(hint_color) })
    -- set_hl("DiagnosticVirtualTextWarn", { fg = warn_color, bg = Darken_hex(warn_color) })
    -- set_hl("DiagnosticVirtualTextError", { fg = error_color, bg = Darken_hex(error_color) })
    -- set_hl("Type", { link = "String" })
    -- set_hl("Delimiter", { link = "Variable" })
    -- set_hl("Statement", { fg = Get_hl_hex("Identifier", "fg"), italic = true })
  end,
})

-- highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})
