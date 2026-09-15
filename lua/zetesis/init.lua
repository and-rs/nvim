local M = {}

local function binary_path()
  local extension = vim.uv.os_uname().sysname == "Windows_NT" and ".exe" or ""
  return vim.fn.stdpath("config") .. "/zetesis/zig-out/bin/zt" .. extension
end

local function open_window(title)
  local width = math.max(1, math.min(100, vim.o.columns - 4))
  local height = math.max(1, math.min(17, vim.o.lines - 4))
  local buffer = vim.api.nvim_create_buf(false, true)
  local window = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 3),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    style = "minimal",
  })
  vim.bo[buffer].bufhidden = "wipe"
  vim.wo[window].number = false
  vim.wo[window].relativenumber = false
  vim.wo[window].signcolumn = "no"
  return buffer, window
end

function M.run(args, opts)
  opts = opts or {}
  local bin = binary_path()
  if vim.fn.executable(bin) ~= 1 then
    vim.notify("zetesis binary missing: run `just bootstrap`", vim.log.levels.ERROR)
    return
  end

  local output_file = vim.fn.tempname()
  local action_file = vim.fn.tempname()
  local command = { bin, unpack(args), "--output-file", output_file, "--action-file", action_file }
  local buffer, window = open_window(opts.title or "Zetesis")
  local job = vim.fn.jobstart(command, {
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(window) then
          vim.api.nvim_win_close(window, true)
        end
        local lines = vim.fn.filereadable(output_file) == 1 and vim.fn.readfile(output_file) or {}
        local action_lines = vim.fn.filereadable(action_file) == 1 and vim.fn.readfile(action_file) or {}
        vim.fn.delete(output_file)
        vim.fn.delete(action_file)
        if code == 0 and opts.on_select then
          opts.on_select(action_lines[1] or "edit", lines)
        end
      end)
    end,
  })
  if job <= 0 then
    vim.fn.delete(output_file)
    vim.fn.delete(action_file)
    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
    vim.notify("failed to start zetesis", vim.log.levels.ERROR)
    return
  end
  vim.api.nvim_set_current_buf(buffer)
  vim.cmd.startinsert()
end

return M
