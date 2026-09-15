local zetesis = require("zetesis")

local M = {}

local commands = {
  edit = "edit",
  vsplit = "vsplit",
  tabedit = "tabedit",
}

local function path_join(cwd, path)
  if path:sub(1, 1) == "/" then
    return path
  end
  return cwd .. "/" .. path
end

local function open_selection(cwd, action, paths)
  if #paths == 0 then
    return
  end
  if action == "quickfix" then
    local items = {}
    for _, path in ipairs(paths) do
      table.insert(items, { filename = path_join(cwd, path) })
    end
    vim.fn.setqflist({}, " ", { title = "Zetesis", items = items })
    vim.cmd.copen()
    return
  end

  local command = commands[action]
  if not command then
    vim.notify("unknown zetesis action: " .. action, vim.log.levels.ERROR)
    return
  end
  for _, path in ipairs(paths) do
    vim.cmd[command](vim.fn.fnameescape(path_join(cwd, path)))
  end
end

function M.open()
  local cwd = vim.uv.cwd()
  zetesis.run({ "files", "--cwd", cwd, "--current-file", vim.api.nvim_buf_get_name(0) }, {
    title = "Zetesis Files",
    on_select = function(action, paths)
      open_selection(cwd, action, paths)
    end,
  })
end

return M
