local keys = { "A", "S", "D", "F" }
_G.Tabliner = function()
  local items = {}
  local current = vim.fn.tabpagenr()
  for i = 1, vim.fn.tabpagenr("$") do
    local buflist = vim.fn.tabpagebuflist(i)
    local bufnr = buflist[vim.fn.tabpagewinnr(i)]
    local name = vim.fn.bufname(bufnr)
    if vim.bo[bufnr].filetype == "alpha" then
      name = "Alpha"
    elseif name == "" then
      name = "New"
    else
      name = vim.fn.fnamemodify(name, ":t")
    end
    local active = i == current
    local hl = active and "%#TabLineSel#" or "%#TabLine#"
    local khl = active and "%#TabKeySel#" or "%#TabKey#"
    local key = (keys[i] or tostring(i)):upper()
    table.insert(items, string.format("%s %s%s%s %s ", hl, khl, key, hl, name))
  end
  return table.concat(items) .. "%#TabLineFill#%T"
end
vim.opt.tabline = "%!v:lua.Tabliner()"
