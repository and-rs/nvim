local M = {}

M.palettes = {
  ["tokyonight"] = {
    NvimRed = "#f7768e",
    NvimOrange = "#ff966c",
    NvimYellow = "#e0af68",
    NvimGreen = "#c3e88d",
    NvimTeal = "#73daca",
    NvimCyan = "#7dcfff",
    NvimBlue = "#7aa2f7",
    NvimViolet = "#bb9af7",
    NvimPink = "#ff007c",
    NvimGrey = "#565f89",
  },
  ["tokyonight-day"] = {
    NvimRed = "#f52a65",
    NvimOrange = "#b15c00",
    NvimYellow = "#8c6c3e",
    NvimGreen = "#587539",
    NvimTeal = "#118c74",
    NvimCyan = "#007197",
    NvimBlue = "#2e7de9",
    NvimViolet = "#7847bd",
    NvimPink = "#d20065",
    NvimGrey = "#68709a",
  },
}

---@return string
local function current_palette_name()
  local colors_name = vim.g.colors_name

  if colors_name == "tokyonight-day" then
    return colors_name
  end

  if colors_name == "tokyonight" and vim.o.background == "light" then
    return "tokyonight-day"
  end

  return "tokyonight"
end

---@return table<string, string>
function M.colors()
  return M.palettes[current_palette_name()] or M.palettes["tokyonight"]
end

---@return nil
function M.apply()
  for group, fg in pairs(M.colors()) do
    vim.api.nvim_set_hl(0, group, { fg = fg })
  end
end

return M
