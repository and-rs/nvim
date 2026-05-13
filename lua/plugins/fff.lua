vim.pack.add({ { src = "https://github.com/dmtrKovalenko/fff.nvim", version = "9ae3824" } })

local fff = require("fff")
local fff_utils = require("fff.utils")

local original_resolve_config_value = fff_utils.resolve_config_value
fff_utils.resolve_config_value = function(
    value,
    terminal_width,
    terminal_height,
    validator,
    default,
    key
)
  if key == "layout.height" and type(value) == "number" and value > 1 then
    return math.min(value, terminal_height) / terminal_height
  end
  return original_resolve_config_value(
    value,
    terminal_width,
    terminal_height,
    validator,
    default,
    key
  )
end

local function get_dynamic_width()
  local cols = vim.o.columns
  return math.min(76, cols - 4) / cols
end

fff.setup({
  prompt = "> ",
  title = "Files",
  lazy_sync = true,
  layout = {
    row = 0.098,
    height = math.floor(vim.o.lines / 2) + 2,
    show_scrollbar = true,
    prompt_position = "top",
  },
  preview = {
    enabled = false,
  },
  keymaps = {
    select_tab = "<C-t>",
    select_split = "<C-h>",
    select_vsplit = "<C-v>",
    toggle_select = "<C-y>",
    send_to_quickfix = "<C-q>",
  },
  hl = {
    border = "FloatBorder",
    normal = "FloatBorder",
    cursor = "FinderSel",
    matched = "FinderMatch",
    title = "FloatBorder",
    prompt = "Special",
    active_file = "Select",
    frecency = "Number",
    combo_header = "Number",

    git_modified = "RainbowDelimiterYellow",
    git_sign_modified = "RainbowDelimiterYellow",
    git_sign_modified_selected = "RainbowDelimiterYellow",

    git_staged = "RainbowDelimiterCyan",
    git_sign_staged = "RainbowDelimiterCyan",
    git_sign_staged_selected = "RainbowDelimiterCyan",

    git_deleted = "FFFGitDeleted",
    git_sign_deleted = "FFFGitSignDeleted",
    git_sign_deleted_selected = "FFFGitSignDeletedSelected",

    git_renamed = "RainbowDelimiterViolet",
    git_sign_renamed = "RainbowDelimiterViolet",
    git_sign_renamed_selected = "RainbowDelimiterViolet",

    git_untracked = "RainbowDelimiterGreen",
    git_sign_untracked = "RainbowDelimiterGreen",
    git_sign_untracked_selected = "RainbowDelimiterGreen",

    git_ignored = "NvimGrey",
    git_sign_ignored = "NvimGrey",
    git_sign_ignored_selected = "NvimGrey",
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

vim.keymap.set("n", "<leader>sf", function()
  fff.find_files({
    layout = {
      width = get_dynamic_width(),
    },
  })
end, { desc = "Recent Files" })
