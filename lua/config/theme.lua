local M = {}

M.path = vim.fs.normalize(vim.fn.expand("~/.config/colors/current.lua"))
M.palette = nil
M.sourced = false

local function notify_missing(reason)
  vim.notify(
    reason .. "\nExpected " .. M.path .. "\nRun `just apply` in dotfiles.",
    vim.log.levels.WARN
  )
end

function M.load()
  if M.sourced then
    return true
  end

  if vim.uv.fs_stat(M.path) == nil then
    notify_missing("Theme file missing.")
    return false
  end

  local ok, palette = pcall(dofile, M.path)
  if not ok or type(palette) ~= "table" then
    notify_missing("Theme file invalid.")
    return false
  end

  M.palette = palette
  M.sourced = true
  return true
end

function M.bg_is_light()
  local bg = M.palette and M.palette.bg
  if type(bg) ~= "string" then
    return false
  end
  local hex = bg:gsub("#", "")
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)
  if not r or not g or not b then
    return false
  end
  return (0.299 * r + 0.587 * g + 0.114 * b) > 127
end

M.load()

return M
