vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "fff" and (kind == "install" or kind == "update") then
      if not ev.data.active then
        vim.cmd.packadd("fff")
      end
      require("fff.download").download_or_build_binary()
    end
  end,
})

vim.pack.add({ "https://github.com/dmtrKovalenko/fff" })

local p = require("config.theme").palette
local color = require("config.coloring")

local function apply_theme_highlights()
  color.set("FFFTitle", { link = "FloatBorder" })
  color.set("FFFCursor", { fg = p.blue, bg = p.surface2, bold = true })
  color.set("FFFSelected", { fg = p.blue, bg = p.surface2 })
  color.set("FFFSelectedActive", { fg = p.white, bg = p.blue, bold = true })

  local git_colors = {
    Staged = p.green,
    Modified = p.blue,
    Deleted = p.red,
    Renamed = p.cyan,
    Untracked = p.yellow,
    Ignored = p.surface5,
  }
  for status, fg in pairs(git_colors) do
    color.set("FFFGit" .. status, { fg = fg })
    color.set("FFFGitSign" .. status, { fg = fg })
    color.set("FFFGitSign" .. status .. "Selected", { fg = fg, bg = p.selection })
  end
end

apply_theme_highlights()
vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = color.augroup,
  callback = apply_theme_highlights,
})

require("fff").setup({
  prompt = "> ",
  lazy_sync = true,
  title = "Files",
  preview = { enabled = false },
  hl = {
    title = "FFFTitle",
    cursor = "FFFCursor",
    selected = "FFFSelected",
    selected_active = "FFFSelectedActive",
    git_staged = "FFFGitStaged",
    git_modified = "FFFGitModified",
    git_deleted = "FFFGitDeleted",
    git_renamed = "FFFGitRenamed",
    git_untracked = "FFFGitUntracked",
    git_ignored = "FFFGitIgnored",
    git_sign_staged = "FFFGitSignStaged",
    git_sign_modified = "FFFGitSignModified",
    git_sign_deleted = "FFFGitSignDeleted",
    git_sign_renamed = "FFFGitSignRenamed",
    git_sign_untracked = "FFFGitSignUntracked",
    git_sign_ignored = "FFFGitSignIgnored",
    git_sign_staged_selected = "FFFGitSignStagedSelected",
    git_sign_modified_selected = "FFFGitSignModifiedSelected",
    git_sign_deleted_selected = "FFFGitSignDeletedSelected",
    git_sign_renamed_selected = "FFFGitSignRenamedSelected",
    git_sign_untracked_selected = "FFFGitSignUntrackedSelected",
    git_sign_ignored_selected = "FFFGitSignIgnoredSelected",
  },
  layout = {
    prompt_position = "top",
    width = function(cols)
      return math.max(1, math.min(84, cols - 4) + 2) / cols
    end,
    height = function(_, lines)
      return math.max(1, math.floor(lines / 2) + 2) / lines
    end,
    -- fzf-lua row=0.25 is leftover space. Keep fzf height here so extra 2 grows down.
    row = function(_, lines)
      local height = math.max(1, math.floor(lines / 2))
      local fzf_row = math.floor((lines - height) * 0.25)
      return math.max(1, fzf_row - 1) / lines
    end,
  },
})

vim.keymap.set("n", "<leader>sf", function()
  require("fff").find_files()
end, { desc = "Files" })
vim.keymap.set("n", "<leader>sg", function()
  require("fff").live_grep()
end, { desc = "Grep" })
