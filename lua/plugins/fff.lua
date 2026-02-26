MiniDeps.now(function()
  MiniDeps.add({
    source = "dmtrKovalenko/fff.nvim",
    hooks = {
      post_checkout = function()
        require("fff.download").download_or_build_binary()
      end,
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
      -- Show scrollbar for pagination
      show_scrollbar = true,
    },
    preview = {
      enabled = false,
    },
    keymaps = {
      select_split = "<C-h>",
      select_vsplit = "<C-v>",
      select_tab = "<C-t>",
      -- Multi-select keymaps for quickfix
      toggle_select = "<C-y>",
      send_to_quickfix = "<C-q>",
    },
    hl = {
      border = "FloatBorder",
      normal = "FloatBorder",
      cursor = "Visual",
      matched = "Substitute",
      title = "FloatBorder",
      prompt = "Special",
      active_file = "Select",
      frecency = "Number",
      combo_header = "Number",

      git_modified = "NvimYellow",
      git_sign_modified = "NvimYellow",
      git_sign_modified_selected = "NvimYellow",

      git_staged = "NvimCyan",
      git_sign_staged = "NvimCyan",
      git_sign_staged_selected = "NvimCyan",

      git_deleted = "FFFGitDeleted",
      git_sign_deleted = "FFFGitSignDeleted",
      git_sign_deleted_selected = "FFFGitSignDeletedSelected",

      git_renamed = "NvimPink",
      git_sign_renamed = "NvimPink",
      git_sign_renamed_selected = "NvimPink",

      git_untracked = "NvimGreen",
      git_sign_untracked = "NvimGreen",
      git_sign_untracked_selected = "NvimGreen",

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
