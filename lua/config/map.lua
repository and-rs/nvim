local M = {}

function M.set(mode, keys, action, desc, opts)
  local defaults = {
    desc = desc or "",
    noremap = true,
  }

  vim.keymap.set(mode, keys, action, vim.tbl_extend("force", defaults, opts or {}))
end

return M
