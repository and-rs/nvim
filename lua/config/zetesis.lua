local M = {}

local function config_root()
  return vim.fn.stdpath("config")
end

local function binary_path()
  local extension = vim.uv.os_uname().sysname == "Windows_NT" and ".exe" or ""
  return config_root() .. "/zetesis/zig-out/bin/zt" .. extension
end

local function project_root()
  return vim.uv.cwd()
end

local function path_join(left, right)
  if right:sub(1, 1) == "/" then
    return right
  end
  return left .. "/" .. right
end

local commands = {
  edit = "edit",
  vsplit = "vsplit",
  tabedit = "tabedit",
}

local function positive_integer(value)
  return type(value) == "number" and value > 0 and value % 1 == 0 and value or nil
end

local function parse_json_entry(line)
  local ok, decoded = pcall(vim.json.decode, line)
  if not ok or type(decoded) ~= "table" or type(decoded.action) ~= "string" then
    return nil
  end

  local kind = decoded.kind or "file"
  if kind ~= "file" and kind ~= "location" and kind ~= "text" then
    return nil
  end
  if kind == "text" then
    if type(decoded.text) ~= "string" then
      return nil
    end
  elseif type(decoded.path) ~= "string" then
    return nil
  end

  return {
    action = decoded.action,
    kind = kind,
    path = decoded.path,
    line = positive_integer(decoded.line),
    col = positive_integer(decoded.col),
    text = decoded.text,
  }
end

local function parse_legacy_entry(line)
  local tab = line:find("\t", 1, true)
  if tab then
    return { action = line:sub(1, tab - 1), kind = "file", path = line:sub(tab + 1) }
  end
  return { action = "edit", kind = "file", path = line }
end

local function parse_output(lines)
  local entries = {}
  for _, line in ipairs(lines) do
    if line ~= "" then
      local entry = parse_json_entry(line)
      if entry then
        table.insert(entries, entry)
      elseif line:sub(1, 1) ~= "{" then
        table.insert(entries, parse_legacy_entry(line))
      end
    end
  end
  return entries
end

local function open_text(entry, command)
  vim.cmd[command](vim.api.nvim_create_buf(false, true))
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(entry.text, "\n", { plain = true }))
end

local function open_quickfix(cwd, entries)
  local items = {}
  for _, entry in ipairs(entries) do
    local item = { text = entry.text or entry.path }
    if entry.kind ~= "text" then
      item.filename = path_join(cwd, entry.path)
      item.lnum = entry.line or 1
      item.col = entry.col or 1
    end
    table.insert(items, item)
  end
  vim.fn.setqflist({}, " ", { title = "Zetesis", items = items })
  vim.cmd.copen()
end

local function execute_entries(cwd, entries)
  if #entries == 0 then
    return
  end
  if entries[1].action == "quickfix" then
    open_quickfix(cwd, entries)
    return
  end

  for _, entry in ipairs(entries) do
    local command = commands[entry.action]
    if not command then
      vim.notify("unknown zetesis action: " .. entry.action, vim.log.levels.ERROR)
      return
    end
    if entry.kind == "text" then
      open_text(entry, command)
    else
      vim.cmd[command](vim.fn.fnameescape(path_join(cwd, entry.path)))
      if entry.line then
        vim.api.nvim_win_set_cursor(0, { entry.line, math.max((entry.col or 1) - 1, 0) })
      end
    end
  end
end

local function open_window()
  local width = math.max(1, math.min(100, vim.o.columns - 4))
  local height = math.max(1, math.min(17, vim.o.lines - 4))
  local row = math.floor((vim.o.lines - height) / 3)
  local col = math.floor((vim.o.columns - width) / 2)
  local buffer = vim.api.nvim_create_buf(false, true)
  local window = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    title = " Zetesis Files ",
    title_pos = "center",
    style = "minimal",
  })
  vim.bo[buffer].bufhidden = "wipe"
  vim.wo[window].number = false
  vim.wo[window].relativenumber = false
  vim.wo[window].signcolumn = "no"
  return buffer, window
end

local function ensure_binary()
  local bin = binary_path()
  if vim.fn.executable(bin) ~= 1 then
    vim.notify("zetesis binary missing: run `cd zetesis && zig build`", vim.log.levels.ERROR)
    return nil
  end
  return bin
end

local function run_zt(subcommand, opts)
  opts = opts or {}
  local bin = ensure_binary()
  if not bin then
    return
  end

  local cwd = project_root()
  local output_file = vim.fn.tempname()
  local buffer, window = open_window()
  local command = { bin, subcommand, "--cwd", cwd, "--output-file", output_file }
  if opts.current_file and opts.current_file ~= "" then
    command[#command + 1] = "--current-file"
    command[#command + 1] = opts.current_file
  end

  local job = vim.fn.termopen(command, {
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(window) then
          vim.api.nvim_win_close(window, true)
        end
        if code ~= 0 then
          vim.fn.delete(output_file)
          return
        end
        local lines = vim.fn.readfile(output_file)
        vim.fn.delete(output_file)
        execute_entries(cwd, parse_output(lines))
      end)
    end,
  })
  if job <= 0 then
    vim.fn.delete(output_file)
    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
    vim.notify("failed to start zetesis", vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_set_current_buf(buffer)
  vim.cmd.startinsert()
end

function M.files()
  run_zt("files", { current_file = vim.api.nvim_buf_get_name(0) })
end

vim.api.nvim_create_user_command("ZetesisFiles", M.files, {})

M._parse_output = parse_output

return M
