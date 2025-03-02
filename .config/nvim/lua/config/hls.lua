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

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  group = vim.api.nvim_create_augroup("Color", {}),
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(
      0,
      "WinBorder",
      { bg = Get_hl_hex("NormalFloat", "bg"), fg = Get_hl_hex("Comment", "fg") }
    )
    vim.api.nvim_set_hl(0, "WinSeparator", { link = "WinBorder" })
    vim.api.nvim_set_hl(0, "FloatBorder", { link = "WinBorder" })
    vim.api.nvim_set_hl(0, "FloatTitle", { link = "WinBorder" })
    vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { underline = true })

    vim.api.nvim_set_hl(0, "NeoTreeNormal", { link = "NormalFloat" })
    vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { fg = Get_hl_hex("Function", "fg") })
    vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = Get_hl_hex("Function", "fg") })
    vim.api.nvim_set_hl(0, "NeoTreeGitUnstaged", { link = "Changed" })
    vim.api.nvim_set_hl(0, "NeoTreeGitModified", { link = "Changed" })
    vim.api.nvim_set_hl(0, "NeoTreeGitUntracked", { link = "Added" })
    vim.api.nvim_set_hl(0, "NeoTreeGitRenamed", { link = "Added" })
    vim.api.nvim_set_hl(0, "NeoTreeGitConflict", { link = "Removed" })
    vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", { link = "WinBorder" })
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
