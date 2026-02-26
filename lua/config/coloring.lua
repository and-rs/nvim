local M = {}

M.augroup = vim.api.nvim_create_augroup("Highlighting", { clear = false })

---@param highlight string
---@param options vim.api.keyset.highlight
---@return nil
function M.set(highlight, options)
  vim.api.nvim_set_hl(0, highlight, options)
end

---@param name string
---@param option "fg" | "bg"
---@return string | nil
function M.get(name, option)
  if type(name) ~= "string" or (option ~= "fg" and option ~= "bg") then
    error("Invalid arguments. Usage: highlight(name: string, option: 'fg' | 'bg')")
  end
  local hl = vim.api.nvim_get_hl(0, { name = name })
  local color = hl[option]
  if not color then
    return nil
  end
  return string.format("#%06x", color)
end

---@param hex string?
---@return string
---@throws "No hex was passed" | "Not a proper hex"
function M.validate_hex(hex)
  if not hex then
    error("No hex was passed")
  end
  if not hex:match("^#%x%x%x%x%x%x$") then
    error("Not a proper hex")
  end
  return hex
end

---@param hex string?
---@return number?, number?, number?
function M.hex_to_rgb(hex)
  hex = M.validate_hex(hex)
  hex = hex:gsub("#", "")
  return tonumber("0x" .. hex:sub(1, 2)),
    tonumber("0x" .. hex:sub(3, 4)),
    tonumber("0x" .. hex:sub(5, 6))
end

---@param r integer
---@param g integer
---@param b integer
---@return string
function M.rgb_to_hex(r, g, b)
  local clamp = function(v)
    return math.max(0, math.min(255, v))
  end
  return string.format("#%02x%02x%02x", clamp(r), clamp(g), clamp(b))
end

---@param hex string | nil
---@param factor number | nil
---@return string
function M.adjust_hex(hex, factor)
  hex = M.validate_hex(hex)

  factor = factor or 1
  if factor < 0 then
    factor = 0
  end
  if factor > 2 then
    factor = 2
  end

  local r, g, b = M.hex_to_rgb(hex)

  local function clamp(v)
    if v < 0 then
      return 0
    end
    if v > 255 then
      return 255
    end
    return v
  end

  local nr, ng, nb
  if factor <= 1 then
    nr = math.floor(r * factor + 0.5)
    ng = math.floor(g * factor + 0.5)
    nb = math.floor(b * factor + 0.5)
  else
    local t = factor - 1
    nr = math.floor(r + (255 - r) * t + 0.5)
    ng = math.floor(g + (255 - g) * t + 0.5)
    nb = math.floor(b + (255 - b) * t + 0.5)
  end

  nr, ng, nb = clamp(nr), clamp(ng), clamp(nb)
  return M.rgb_to_hex(nr, ng, nb)
end

---@param hex string | nil
---@param factor number | nil
---@return string
function M.darken_hex(hex, factor)
  if not hex then
    error("No hex passed, verify source")
  end

  factor = factor or 0.15
  if factor < 0 or factor > 1 then
    factor = 0.15
  end

  return M.adjust_hex(hex, 1 - factor)
end

---@param hex string | nil
---@param factor number | nil
---@return string
function M.lighten_hex(hex, factor)
  if not hex then
    error("No hex passed, verify source")
  end

  factor = factor or 0.15
  if factor < 0 or factor > 1 then
    factor = 0.15
  end

  return M.adjust_hex(hex, 1 + factor)
end

return M
