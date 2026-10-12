local M = {}

local state = { job_id = nil, buf = nil }

local function notify(message, level)
  vim.notify(message, level, { title = "Tidal" })
end

local function running()
  if not state.job_id then
    return false
  end

  if vim.fn.jobwait({ state.job_id }, 0)[1] == -1 then
    return true
  end

  state.job_id = nil
  return false
end

local function show_terminal(buf, source_win, height)
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    vim.api.nvim_set_current_win(source_win)
    vim.cmd("botright split")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  end

  vim.api.nvim_win_set_height(win, height)
  vim.api.nvim_set_current_win(source_win)
end

local function send(text)
  if not running() then
    notify("Tidal is not running. Start it with <leader>ts.", vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(vim.api.nvim_chan_send, state.job_id, text)
  if not ok then
    notify("Could not send to Tidal: " .. err, vim.log.levels.ERROR)
  end
end

function M.start()
  if vim.fn.executable("tidal") ~= 1 then
    notify("Could not find tidal on Neovim's PATH.", vim.log.levels.ERROR)
    return
  end

  local source_win = vim.api.nvim_get_current_win()
  local height = math.max(4, math.floor(vim.api.nvim_win_get_height(source_win) * 0.2))

  if running() then
    show_terminal(state.buf, source_win, height)
    return
  end

  local old_buf = state.buf
  local win = old_buf and vim.api.nvim_buf_is_valid(old_buf) and vim.fn.bufwinid(old_buf) or -1
  if win == -1 then
    vim.api.nvim_set_current_win(source_win)
    vim.cmd("botright split")
    win = vim.api.nvim_get_current_win()
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  if old_buf and vim.api.nvim_buf_is_valid(old_buf) then
    pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
  end

  state.buf = buf
  vim.api.nvim_set_current_win(win)

  local job_id
  job_id = vim.fn.termopen({ "tidal" }, {
    cwd = vim.fn.getcwd(),
    on_exit = function(_, code)
      vim.schedule(function()
        if state.job_id ~= job_id then
          return
        end

        state.job_id = nil
        if code ~= 0 then
          notify("Tidal exited with code " .. code .. ".", vim.log.levels.WARN)
        end
      end)
    end,
  })

  if job_id <= 0 then
    state.buf = nil
    notify("Could not start the Tidal terminal.", vim.log.levels.ERROR)
    vim.api.nvim_set_current_win(source_win)
    return
  end

  state.job_id = job_id
  vim.api.nvim_win_set_height(win, height)
  vim.api.nvim_set_current_win(source_win)
end

function M.send_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local text = table.concat(lines, "\n")
  if text == "" then
    return
  end

  send(text .. "\n")
end

function M.hush()
  send("hush\n")
end

return M
