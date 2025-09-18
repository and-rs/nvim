MiniDeps.now(function()
  MiniDeps.add({ source = "nvim-lualine/lualine.nvim" })

  local function get_git_branch()
    local handle = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")
    if not handle then
      return nil
    end
    local branch = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    return (branch ~= "" and branch ~= "HEAD") and branch or nil
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
      },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {
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
end)
