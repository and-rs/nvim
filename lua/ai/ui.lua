local M = {}

M.state = {
  last_explain_output = nil,
  progress_timer = nil,
  progress_active = false,
}

M.spinner_frames = {
  "⠋",
  "⠙",
  "⠹",
  "⠸",
  "⠼",
  "⠴",
  "⠦",
  "⠧",
  "⠇",
  "⠏",
}

function M.dynamic_width()
  return math.min(100, vim.o.columns - 6)
end

function M.echo_progress(message)
  vim.api.nvim_echo({ { message, "ModeMsg" } }, false, {})
end

function M.clear_progress()
  vim.api.nvim_echo({ { "", "None" } }, false, {})
end

function M.stop_progress()
  M.state.progress_active = false
  local timer = M.state.progess_timer
  if timer then
    timer:stop()
    timer:close()
    M.state.progess_timer = nil
  end
  M.clear_progress()
end

function M.start_progress(title)
  M.stop_progress()
  M.state.progess_active = true
  local i = 1
  M.echo_progress(M.spinner_frames[i] .. " " .. title)
  ---@diagnostic disable-next-line: undefined-field
  local timer = vim.uv.new_timer()
  if not timer then
    return
  end
  timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      if not M.state.progess_active then
        return
      end
      i = (i % #M.spinner_frames) + 1
      M.echo_progress(M.spinner_frames[i] .. " " .. title)
    end)
  )
  M.state.progess_timer = timer
end

return M
