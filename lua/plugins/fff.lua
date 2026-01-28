---@diagnostic disable: undefined-field
MiniDeps.now(function()
  MiniDeps.add({
    source = "dmtrKovalenko/fff.nvim",
    hooks = {
      post_install = function()
        require("fff.download").download_or_build_binary()
      end,
    },
  })

  vim.o.winborder = "rounded"
  local fff = require("fff")

  fff.setup({
    prompt = "> ",
    title = "Files",
    layout = {
      row = 0.08,
      height = 0.5,
      prompt_position = "top",
      show_scrollbar = true, -- Show scrollbar for pagination
    },
    preview = {
      enabled = false,
    },
    history = {
      min_combo_count = 100,
    },
    keymaps = {
      select_split = "<C-h>",
      select_vsplit = "<C-v>",
      select_tab = "<C-t>",
      -- multi-select keymaps for quickfix
      toggle_select = "<C-y>",
      send_to_quickfix = "<C-q>",
    },
    hl = {
      border = "FloatBorder",
      normal = "FloatBorder",
      cursor = "CursorLine",
      matched = "Substitute",
      title = "FloatBorder",
      prompt = "Special",
      active_file = "Select",
      frecency = "Number",
      combo_header = "Number",
    },

    -- Git integration
    git = {
      status_text_color = false, -- Apply git status colors to filename text (default: false, only sign column)
    },
    debug = {
      enabled = false,
      show_scores = false,
      show_file_info = false,
    },
    logging = {
      enabled = false,
    },
  })

  local function get_dynamic_width()
    local cols = vim.o.columns
    return math.min(76, cols - 4) / cols
  end

  vim.keymap.set("n", "<leader>sf", function()
    fff.find_files({
      layout = {
        width = get_dynamic_width(),
      },
    })
  end, { desc = "Recent Files" })
end)
