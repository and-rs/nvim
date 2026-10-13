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

local function send(text)
  if not running() then
    notify("Tidal is not running. Open the Live tab with <leader>tl.", vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(vim.api.nvim_chan_send, state.job_id, text)
  if not ok then
    notify("Could not send to Tidal: " .. err, vim.log.levels.ERROR)
  end
end

function M.start(target_win)
  target_win = target_win or vim.api.nvim_get_current_win()

  if running() then
    if vim.api.nvim_buf_is_valid(state.buf) then
      vim.api.nvim_win_set_buf(target_win, state.buf)
    end
    return
  end

  if vim.fn.executable("tidal") ~= 1 then
    notify("Could not find tidal on Neovim's PATH.", vim.log.levels.ERROR)
    return
  end

  local old_buf = state.buf
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  local previous_buf = vim.api.nvim_win_get_buf(target_win)
  vim.api.nvim_win_set_buf(target_win, buf)

  local job_id
  vim.api.nvim_win_call(target_win, function()
    job_id = vim.fn.jobstart({ "tidal" }, {
      cwd = vim.fn.getcwd(),
      term = true,
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
  end)

  if job_id <= 0 then
    notify("Could not start the Tidal terminal.", vim.log.levels.ERROR)
    if vim.api.nvim_buf_is_valid(previous_buf) then
      vim.api.nvim_win_set_buf(target_win, previous_buf)
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    return
  end

  pcall(vim.api.nvim_buf_set_name, buf, "Tidal")
  state.buf = buf
  state.job_id = job_id
  if old_buf and old_buf ~= buf and vim.api.nvim_buf_is_valid(old_buf) then
    pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
  end
end

function M.send_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local text = table.concat(lines, "\n"):gsub("\t", "  ")
  if text == "" then
    return
  end

  send(text .. "\n")
end

function M.hush()
  send("hush\n")
end

return M
