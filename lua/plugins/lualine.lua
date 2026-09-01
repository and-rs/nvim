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

local function is_outside_cwd()
  local current_cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
  if current_cwd ~= "/" then
    current_cwd = current_cwd:gsub("/+$", "")
  end
  local buffer_name = vim.api.nvim_buf_get_name(0)
  if buffer_name ~= "" and vim.bo.buftype == "" then
    local buffer_path = vim.fn.fnamemodify(buffer_name, ":p")
    return buffer_path ~= current_cwd
      and (current_cwd == "/" or buffer_path:sub(1, #current_cwd + 1) ~= current_cwd .. "/")
  end
  return false
end

local function cwd()
  local current_cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
  if current_cwd ~= "/" then
    current_cwd = current_cwd:gsub("/+$", "")
  end
  local display_cwd = vim.fn.fnamemodify(current_cwd, ":~")
  return display_cwd
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
local theme = require("config.theme")

local function get_colors()
  if not theme.sourced then
    return nil
  end
  local p = theme.palette
  return {
    bg = p.black,
    red = p.red,
    blue = p.blue,
    cyan = p.cyan,
    green = p.green,
    orange = p.yellow,
    violet = p.magenta,
  }
end

local function get_theme(colors)
  return {
    normal = {
      a = { fg = colors.cyan, bg = colors.bg },
      b = { fg = colors.cyan, bg = colors.bg },
      c = { fg = colors.cyan, bg = colors.bg },
    },
    insert = {
      a = { fg = colors.green, bg = colors.bg },
      b = { fg = colors.green, bg = colors.bg },
      c = { fg = colors.green, bg = colors.bg },
    },
    visual = {
      a = { fg = colors.violet, bg = colors.bg },
      b = { fg = colors.violet, bg = colors.bg },
      c = { fg = colors.violet, bg = colors.bg },
    },
    replace = {
      a = { fg = colors.blue, bg = colors.bg },
      b = { fg = colors.blue, bg = colors.bg },
      c = { fg = colors.blue, bg = colors.bg },
    },
    terminal = {
      a = { fg = colors.violet, bg = colors.bg },
      b = { fg = colors.violet, bg = colors.bg },
      c = { fg = colors.violet, bg = colors.bg },
    },
  }
end

local function setup_lualine()
  local colors = get_colors()

  require("lualine").setup({
    options = {
      icons_enabled = true,
      globalstatus = true,
      component_separators = { left = " ┃ ", right = " ┃ " },
      section_separators = "",
      theme = colors and get_theme(colors) or "auto",
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
        { "mode", padding = { right = 0, left = 2 } },
        cwd,
        {
          function()
            return is_outside_cwd() and "[OUT]" or ""
          end,
          color = colors and { fg = colors.red },
          padding = { left = 1, right = 0 },
          separator = "",
        },
        {
          function()
            return is_outside_cwd() and "/" or ""
          end,
          padding = { left = 0, right = 0 },
          separator = "",
        },
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
          colored = colors ~= nil,
          diff_color = colors and {
            added = { fg = colors.green },
            modified = { fg = colors.blue },
            removed = { fg = colors.red },
          } or nil,
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
