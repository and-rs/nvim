local function lint_progress()
  local linters = require("lint").get_running()
  if #linters == 0 then
    return ""
  end
  return "* " .. table.concat(linters, ", ")
end

-- Returns the current Git branch name, or nil if not in a repo.
local function get_git_branch()
  local handle = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")
  if not handle then
    return nil
  end
  local branch = handle:read("*a"):gsub("%s+$", "")
  handle:close()
  return (branch ~= "" and branch ~= "HEAD") and branch or nil
end

local function harpoon()
  local mark = ""
  if package.loaded["harpoon"] then
    local current_file = vim.fn.expand("%:p")
    for id, item in ipairs(require("harpoon"):list().items) do
      local item_file = vim.fn.fnamemodify(item.value, ":p")
      if item_file == current_file then
        mark = "#" .. id
        break
      end
    end
  end
  return mark
end

local function location()
  local line = vim.fn.line(".")
  local col = vim.fn.charcol(".")
  return line .. ":" .. col
end

require("utils.highlights")
local colors = {
  white = Get_hl_hex("PreProc", "fg"),
  border = Get_hl_hex("Conceal", "fg"),
  background = Get_hl_hex("NormalFloat", "bg"),
}

return {
  "nvim-lualine/lualine.nvim",
  config = function()
    require("lualine").setup({
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      sections = {
        lualine_a = {
          "separator",
          { "mode", padding = { right = 1, left = 2 } },
          {
            "filename",
            path = 0,
            symbols = {
              modified = "*",
              readonly = "×",
              unnamed = "No name",
              newfile = "New file",
            },
          },

          get_git_branch,
          harpoon,
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {
          lint_progress,
          location,
          "progress",
          {
            "vim.bo.filetype",
          },
          {
            "diff",
            symbols = { added = "+", modified = "~", removed = "-" },
            padding = { right = 2, left = 1 },
          },
        },
      },

      options = {
        icons_enabled = true,
        globalstatus = true,
        disabled_filetypes = { "alpha" },
        component_separators = { left = " ╱ ", right = " ╲ " },
        section_separators = "",

        theme = {
          normal = {
            a = { bg = colors.background, fg = colors.white },
            b = { bg = colors.background, fg = colors.white },
            c = { bg = colors.background, fg = colors.white },
          },
        },
      },

      extensions = {
        "nvim-tree",
        "neo-tree",
        "mason",
        "lazy",
        "fzf",
      },
    })
  end,
}
