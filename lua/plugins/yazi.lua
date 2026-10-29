vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
  { src = "https://github.com/mikavilpas/yazi.nvim" },
})

vim.g.loaded_netrwPlugin = 1

local function dynamic_width()
  return math.min(100, vim.o.columns - 6)
end

local function output(command)
  local result = vim.system(command, { text = true }):wait(5000)
  assert(result.code == 0, result.stderr or "Yazi opener timed out")
  return vim.trim(result.stdout)
end

local function notify(message)
  vim.schedule(function()
    vim.notify(tostring(message), vim.log.levels.ERROR)
  end)
end

local function matches(value, glob)
  if not glob then
    return true
  end
  local case = "\\c"
  if glob:sub(1, 2) == "\\s" then
    case, glob = "\\C", glob:sub(3)
  end
  return vim.fn.match(value, case .. vim.fn.glob2regpat(glob)) >= 0
end

local function opener_for(config, path, mime)
  local platform = ({ Linux = "linux", Darwin = "macos", Windows_NT = "windows" })[vim.uv.os_uname().sysname]
  local rules = config.open or {}
  for _, rule in ipairs(rules.rules or rules.prepend_rules or {}) do
    if matches(mime, rule.mime) and matches(path, rule.url) then
      local names = rule.use
      if type(names) == "string" then
        names = { names }
      end
      for _, name in ipairs(names) do
        if name == "edit" then
          return
        end
        for _, opener in ipairs((config.opener or {})[name] or {}) do
          local target = opener["for"]
          if not target or target == platform or (target == "unix" and platform ~= "windows") then
            return opener
          end
        end
        if not (config.opener or {})[name] and (name == "open" or name == "play") then
          return { system = true }
        end
      end
      return
    end
  end
end

local function open_files(paths)
  local ok, err = pcall(function()
    local directory = vim.env.YAZI_CONFIG_HOME
      or ((vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")) .. "/yazi")
    local config = vim.json.decode(output({
      "python3",
      "-c",
      'import json, sys, tomllib; print(json.dumps(tomllib.load(open(sys.argv[1], "rb"))))',
      directory .. "/yazi.toml",
    }))
    local editor_files = {}
    for _, path in ipairs(paths) do
      local mime = "folder/directory"
      if vim.fn.isdirectory(path) == 0 then
        mime = output({ "file", "--brief", "--mime-type", "--dereference", "--", path })
      end
      local opener = opener_for(config, path, mime)
      if not opener then
        editor_files[#editor_files + 1] = path
      elseif opener.system then
        local _, open_err = vim.ui.open(path)
        assert(not open_err, open_err)
      else
        assert(not opener.block, "Use Shift+Enter for blocking openers: " .. opener.run)
        -- Filenames remain shell arguments, not executable shell code.
        local command = opener.run:gsub("%%([%%a-zA-Z])(%d*)", function(kind, index)
          if kind == "%" then
            return "%"
          end
          assert(kind == "s", "Use Shift+Enter for placeholder %" .. kind .. index)
          if index == "" then
            return '"$@"'
          end
          return '"${' .. index .. '}"'
        end)
        local args = { "sh", "-c", command, "yazi-opener", path }
        vim.system(args, { text = true, detach = true }, function(result)
          if result.code ~= 0 then
            notify(result.stderr)
          end
        end)
      end
    end
    local openers = require("yazi.openers")
    if #editor_files == 1 then
      openers.open_file(editor_files[1])
    elseif #editor_files > 1 then
      openers.open_multiple_files(editor_files)
    end
  end)
  if not ok then
    notify(err)
  end
end

require("yazi").setup({
  open_for_directories = true,
  open_file_function = function(path)
    open_files({ path })
  end,
  keymaps = {
    show_help = "<f1>",
    open_file_in_tab = "<c-t>",
    send_to_quickfix_list = "<c-q>",
    open_file_in_vertical_split = "<c-v>",
    open_file_in_horizontal_split = "<c-h>",

    grep_in_directory = "<nop>",
    cycle_open_buffers = "<nop>",
    open_and_pick_window = "<nop>",
    replace_in_directory = "<nop>",
    copy_relative_path_to_selected_files = "<nop>",

    change_working_directory = "<c-p>",
  },
  highlight_hovered_buffers_in_same_directory = false,
  hooks = {
    yazi_opened_multiple_files = open_files,
    before_opening_window = function(window_options)
      window_options.row = 2
      window_options.width = dynamic_width()
      window_options.col = math.floor((vim.o.columns - dynamic_width()) / 2) - 1
    end,
  },
  floating_window_scaling_factor = {
    height = 20,
    width = dynamic_width(),
  },
})

vim.keymap.set(
  { "n", "v" },
  "<leader>fe",
  "<cmd>Yazi<cr>",
  { desc = "Open yazi at the current file" }
)
