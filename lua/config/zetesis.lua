local M = {}

local function config_root()
  return vim.fn.stdpath("config")
end

local function binary_path()
  local extension = vim.uv.os_uname().sysname == "Windows_NT" and ".exe" or ""
  return config_root() .. "/zetesis/zig-out/bin/zt" .. extension
end

local function project_root()
  return vim.fs.root(0, { ".git" }) or vim.uv.cwd()
end

local function path_join(left, right)
  if right:sub(1, 1) == "/" then
    return right
  end
  return left .. "/" .. right
end

local function open_window()
  local width = math.floor(vim.o.columns * 0.60)
  local height = math.floor(vim.o.lines * 0.55)
  local row = math.floor((vim.o.lines - height) / 6)
  local col = math.floor((vim.o.columns - width) / 2)
  local buffer = vim.api.nvim_create_buf(false, true)
  local window = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "single",
    style = "minimal",
  })

  vim.bo[buffer].bufhidden = "wipe"
  vim.wo[window].number = false
  vim.wo[window].relativenumber = false
  vim.wo[window].signcolumn = "no"

  return buffer, window
end

function M.files()
  local bin = binary_path()
  if vim.fn.executable(bin) ~= 1 then
    vim.notify("zetesis binary missing: run `cd zetesis && zig build`", vim.log.levels.ERROR)
    return
  end

  local cwd = project_root()
  local output_file = vim.fn.tempname()
  local current_file = vim.api.nvim_buf_get_name(0)
  local buffer, window = open_window()

  local command = {
    bin,
    "files",
    "--cwd",
    cwd,
    "--current-file",
    current_file,
    "--output-file",
    output_file,
  }

  vim.fn.termopen(command, {
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
        local selection = lines[1]
        if not selection or selection == "" then
          return
        end

        vim.cmd.edit(vim.fn.fnameescape(path_join(cwd, selection)))
      end)
    end,
  })

  vim.api.nvim_set_current_buf(buffer)
  vim.cmd.startinsert()
end

vim.api.nvim_create_user_command("ZetesisFiles", M.files, {})

return M
