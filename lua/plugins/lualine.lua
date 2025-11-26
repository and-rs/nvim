MiniDeps.now(function()
  MiniDeps.add({ source = "nvim-lualine/lualine.nvim" })

  local function get_git_branch()
    local handle = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")
    if not handle then
      return nil
    end
    local branch = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    return (branch ~= "" and branch ~= "HEAD") and branch or ""
  end

  local function location()
    local line = vim.fn.line(".")
    local col = vim.fn.charcol(".")
    if vim.o.columns > 67 then
      return line .. ":" .. col
    else
      return ""
    end
  end

  local function progress()
    local cur = vim.fn.line(".")
    local total = vim.fn.line("$")
    if vim.o.columns > 67 then
      if cur == 1 then
        return "Top"
      elseif cur == total then
        return "Bot"
      else
        return string.format("%2d%%%%", math.floor(cur / total * 100))
      end
    else
      return ""
    end
  end

  local coloring = require("utils.coloring")
  local colors = {
    white = coloring.highlight("Normal", "fg"),
    background = coloring.highlight("NormalFloat", "bg"),
  }

  require("lualine").setup({
    options = {
      icons_enabled = true,
      globalstatus = true,
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
          path = 4,
          new_file_status = true,
          symbols = {
            modified = "*",
            readonly = "×",
            unnamed = "No name",
            newfile = "New file",
          },
        },
      },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {
        location,
        progress,
        {
          "diff",
          colored = true,
          diff_color = {
            added = "GitSignsAdd",
            modified = "GitSignsChange",
            removed = "GitSignsDelete",
          },
          separator = "@",
          symbols = { added = "+", modified = "~", removed = "-" },
          padding = { right = 1, left = 1 },
        },
        {
          get_git_branch,
        },
        {
          "vim.bo.filetype",
          padding = { right = 2, left = 1 },
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
end)
