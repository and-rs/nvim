local M = {}

local state = { job_id = nil, buf = nil, pending = {} }

local function notify(message, level)
  vim.notify(message, level, { title = "SuperCollider" })
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

local function append_output(buf, lines)
  if not vim.api.nvim_buf_is_valid(buf) or #lines == 0 then
    return
  end

  vim.bo[buf].modifiable = true
  local count = vim.api.nvim_buf_line_count(buf)
  if count == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  else
    vim.api.nvim_buf_set_lines(buf, count, count, false, lines)
  end
  vim.bo[buf].modifiable = false
end

local function collect_output(buf, stream, data)
  if not data then
    return
  end

  local output = state.pending[stream] .. table.concat(data, "\n")
  local lines = vim.split(output, "\n", { plain = true, trimempty = false })
  state.pending[stream] = table.remove(lines)

  if #lines > 0 then
    vim.schedule(function()
      append_output(buf, lines)
    end)
  end
end

local function make_output_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  pcall(vim.api.nvim_buf_set_name, buf, "Live")
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  return buf
end

local function send(text)
  if not running() then
    notify("sclang is not running. Open the Live tab with <leader>tl.", vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(vim.api.nvim_chan_send, state.job_id, text .. "\f")
  if not ok then
    notify("Could not send code to sclang: " .. err, vim.log.levels.ERROR)
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

  if vim.fn.executable("sclang") ~= 1 then
    notify("Could not find sclang on Neovim's PATH.", vim.log.levels.ERROR)
    return
  end

  local buf = state.buf
  local created = not buf or not vim.api.nvim_buf_is_valid(buf)
  if created then
    buf = make_output_buffer()
  else
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    vim.bo[buf].modifiable = false
  end

  vim.bo[buf].bufhidden = "hide"
  local previous_buf = vim.api.nvim_win_get_buf(target_win)
  vim.api.nvim_win_set_buf(target_win, buf)
  state.pending = { stdout = "", stderr = "" }

  local cwd = vim.fn.getcwd()
  local job_id
  job_id = vim.fn.jobstart({ "sclang", "-i", "scnvim", "-d", cwd }, {
    cwd = cwd,
    on_stdout = function(_, data)
      collect_output(buf, "stdout", data)
    end,
    on_stderr = function(_, data)
      collect_output(buf, "stderr", data)
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if state.job_id ~= job_id then
          return
        end

        state.job_id = nil
        for _, pending in pairs(state.pending) do
          if pending ~= "" then
            append_output(buf, { pending })
          end
        end
        state.pending = {}

        if code ~= 0 then
          notify("sclang exited with code " .. code .. ".", vim.log.levels.WARN)
        end
      end)
    end,
  })

  if job_id <= 0 then
    notify("Could not start sclang.", vim.log.levels.ERROR)
    if vim.api.nvim_buf_is_valid(previous_buf) then
      vim.api.nvim_win_set_buf(target_win, previous_buf)
    end
    if created then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
    return
  end

  state.buf = buf
  state.job_id = job_id
end

function M.send_selection()
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
  local text = table.concat(lines, "\n")
  if text == "" then
    return
  end

  send(text)
end

return M
