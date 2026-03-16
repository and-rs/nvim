local ui = require("ai.ui")
local M = {}

local function get_visual_selection()
  local start_pos = vim.api.nvim_buf_get_mark(0, "<")
  local end_pos = vim.api.nvim_buf_get_mark(0, ">")
  if start_pos[1] == 0 or end_pos[1] == 0 then
    return nil
  end
  local mode = vim.fn.visualmode()
  local s_row = start_pos[1] - 1
  local s_col = start_pos[2]
  local e_row = end_pos[1] - 1
  local e_col = end_pos[2]

  if mode == "V" then
    s_col = 0
    local line_len = #vim.api.nvim_buf_get_lines(0, e_row, e_row + 1, false)[1]
    e_col = line_len
  elseif mode == "\22" then -- Ctrl-V
    vim.notify("Blockwise visual mode is not supported", vim.log.levels.WARN)
    return nil
  else
    e_col = e_col + 1
  end
  if s_row > e_row or (s_row == e_row and s_col > e_col) then
    s_row, e_row = e_row, s_row
    s_col, e_col = e_col, s_col
  end
  local lines = vim.api.nvim_buf_get_text(0, s_row, s_col, e_row, e_col, {})
  return {
    text = table.concat(lines, "\n"),
    range = {
      start_row = s_row,
      start_col = s_col,
      end_row = e_row,
      end_col = e_col,
      mode = mode,
    },
  }
end

local function get_file_text()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return {
    text = table.concat(lines, "\n"),
    range = nil,
  }
end

local function replace_range(range, text)
  local replacement = vim.split(text:gsub("\n$", ""), "\n", { plain = true })
  vim.api.nvim_buf_set_text(
    0,
    range.start_row,
    range.start_col,
    range.end_row,
    range.end_col,
    replacement
  )
end

local function open_explain_float(content)
  local width = ui.dynamic_width()
  local height = math.floor(vim.o.lines * 0.82)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n", { plain = true }))
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
  vim.keymap.set("n", "q", "<cmd>close<cr>", {
    buffer = buf,
    silent = true,
    noremap = true,
  })
end

local function build_aichat_cmd(instruction, extra_args)
  local cmd = { "aichat", "--role", "transformer", instruction }
  if extra_args then
    vim.list_extend(cmd, extra_args)
  end
  return cmd
end

local function run_aichat(cmd, input, title, on_success)
  ui.start_progress(title)
  vim.system(cmd, { stdin = input, text = true }, function(obj)
    vim.schedule(function()
      ui.stop_progress()
      local stdout = obj.stdout or ""
      local stderr = obj.stderr or ""
      if obj.code ~= 0 then
        local message = stderr ~= "" and stderr or stdout
        if message == "" then
          message = "aichat failed"
        end
        vim.notify(message, vim.log.levels.ERROR)
        return
      end
      on_success(stdout)
    end)
  end)
end

local function aichat_transform(extra_flags)
  local selection = get_visual_selection()
  if not selection or selection.text == "" then
    vim.notify("Visual selection required", vim.log.levels.WARN)
    return
  end
  local input = vim.fn.input("aichat: ")
  if input == "" then
    return
  end
  local extra_args = nil
  if extra_flags and extra_flags ~= "" then
    extra_args = vim.split(extra_flags, "%s+", { trimempty = true })
  end
  local cmd = build_aichat_cmd(input, extra_args)
  run_aichat(cmd, selection.text, "running transform", function(output)
    replace_range(selection.range, output)
  end)
end

local function aichat_explain()
  local mode = vim.fn.mode()
  local payload
  if mode:match("[vV\22]") then
    vim.cmd("normal! \27")
    payload = get_visual_selection()
  else
    payload = get_file_text()
  end
  if not payload or payload.text == "" then
    vim.notify("No content to explain", vim.log.levels.WARN)
    return
  end

  local input = vim.fn.input("aichat explain? ")
  local instruction = input ~= "" and input or "explain this"

  local shell_cmd = string.format(
    "aichat --role teacher --model google:gemini-3-flash-preview '%s' | mdcat -c -P --columns 100",
    instruction:gsub("'", "'\\''")
  )
  local cmd = { "sh", "-c", shell_cmd }

  run_aichat(cmd, payload.text, "running explain", function(output)
    ui.state.last_explain_output = output
    open_explain_float(output)
  end)
end

local function aichat_explain_last()
  local output = ui.state.last_explain_output
  if not output or output == "" then
    vim.notify("No previous explain output", vim.log.levels.WARN)
    return
  end
  open_explain_float(output)
end

vim.keymap.set("v", "<leader>ar", function()
  vim.cmd("normal! \27")
  aichat_transform(nil)
end, { desc = "aichat: replace selection" })

vim.keymap.set({ "v", "n" }, "<leader>ai", aichat_explain, { desc = "aichat: explain context" })
vim.keymap.set("n", "<leader>al", aichat_explain_last, { desc = "aichat: explain last" })

return M
