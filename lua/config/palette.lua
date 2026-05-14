local M = {}

M.colors = {
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
}

---@return nil
function M.apply()
  for group, fg in pairs(M.colors) do
    vim.api.nvim_set_hl(0, group, { fg = fg })
  end
end

return M
