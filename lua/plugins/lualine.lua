vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

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
  if vim.o.columns > 75 then
    return line .. ":" .. col
  else
    return ""
  end
end

local function progress()
  local cur = vim.fn.line(".")
  local total = vim.fn.line("$")
  if vim.o.columns > 75 then
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

local cl = require("config.coloring")

local function get_colors()
  local fallback = cl.get("Normal").fg or "#c0caf5"
  local function fg(name)
    return cl.get(name).fg or fallback
  end

  return {
    white = fg("Normal"),
    red = fg("NvimRed"),
    blue = fg("NvimBlue"),
    cyan = fg("NvimCyan"),
    green = fg("NvimGreen"),
    orange = fg("NvimOrange"),
    violet = fg("NvimViolet"),
  }
end

local function get_theme(colors)
  return {
    normal = {
      a = { fg = colors.white },
      b = { fg = colors.white },
      c = { fg = colors.white },
    },
    insert = {
      a = { fg = colors.green },
      b = { fg = colors.green },
      c = { fg = colors.green },
    },
    visual = {
      a = { fg = colors.cyan },
      b = { fg = colors.cyan },
      c = { fg = colors.cyan },
    },
    replace = {
      a = { fg = colors.red },
      b = { fg = colors.red },
      c = { fg = colors.red },
    },
    terminal = {
      a = { fg = colors.orange },
      b = { fg = colors.orange },
      c = { fg = colors.orange },
    },
  }
end

local function setup_lualine()
  local colors = get_colors()

  require("lualine").setup({
    options = {
      icons_enabled = true,
      globalstatus = true,
      component_separators = { left = " ╱ ", right = " ╲ " },
      section_separators = "",
      theme = get_theme(colors),
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
          padding = { right = 2 },
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
        { location, padding = { left = 2 } },
        progress,
        {
          "diff",
          colored = true,
          diff_color = {
            added = { fg = colors.green },
            modified = { fg = colors.blue },
            removed = { fg = colors.red },
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
      "fzf",
    },
  })

  require("lualine").refresh()
end

setup_lualine()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = cl.augroup,
  callback = setup_lualine,
})

