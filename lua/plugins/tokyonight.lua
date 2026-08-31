local theme = require("config.theme")

vim.pack.add({ "https://github.com/folke/tokyonight.nvim" })

if not theme.sourced then
  return
end

local cl = require("config.coloring")
local p = theme.palette
local light = theme.bg_is_light()
local style = light and "day" or "moon"

vim.o.background = light and "light" or "dark"

---@param c table
local function on_colors(c)
  c.bg = p.bg
  c.bg_dark = p.base
  c.bg_dark1 = p.base
  c.bg_highlight = p.surface2
  c.fg = p.fg
  c.fg_dark = p.white
  c.fg_gutter = p.surface3
  c.comment = p.surface5
  c.dark3 = p.surface3
  c.dark5 = p.surface5
  c.black = p.black
  c.red = p.red
  c.red1 = p.red
  c.green = p.green
  c.green1 = p.cyan
  c.green2 = p.cyan
  c.yellow = p.yellow
  c.orange = p.yellow
  c.blue = p.blue
  c.blue0 = p.selection
  c.blue1 = p.cyan
  c.blue2 = p.cyan
  c.blue5 = p.cyan
  c.blue6 = p.cyan
  c.blue7 = p.surface3
  c.cyan = p.cyan
  c.magenta = p.magenta
  c.magenta2 = p.red
  c.purple = p.magenta
  c.teal = p.cyan
  c.terminal_black = p.bright_black
  c.git.add = p.green
  c.git.change = p.blue
  c.git.delete = p.red
  c.git.ignore = p.surface4
  c.border = p.black
  c.border_highlight = p.blue
  c.bg_popup = p.base
  c.bg_statusline = p.base
  c.bg_sidebar = p.bg
  c.bg_float = p.surface1
  c.bg_visual = p.selection
  c.bg_search = p.surface2
  c.fg_sidebar = p.white
  c.fg_float = p.fg
  c.error = p.red
  c.todo = p.blue
  c.warning = p.yellow
  c.info = p.cyan
  c.hint = p.cyan
  c.diff.add = cl.adjust_hex(p.green, 0.25)
  c.diff.delete = cl.adjust_hex(p.red, 0.25)
  c.diff.change = cl.adjust_hex(p.blue, 0.15)
  c.diff.text = p.surface3
  c.rainbow = {
    p.blue,
    p.yellow,
    p.green,
    p.cyan,
    p.magenta,
    p.magenta,
    p.yellow,
    p.red,
  }
  c.terminal.black = p.black
  c.terminal.black_bright = p.bright_black
  c.terminal.red = p.red
  c.terminal.red_bright = p.red
  c.terminal.green = p.green
  c.terminal.green_bright = p.green
  c.terminal.yellow = p.yellow
  c.terminal.yellow_bright = p.yellow
  c.terminal.blue = p.blue
  c.terminal.blue_bright = p.blue
  c.terminal.magenta = p.magenta
  c.terminal.magenta_bright = p.magenta
  c.terminal.cyan = p.cyan
  c.terminal.cyan_bright = p.cyan
  c.terminal.white = p.white
  c.terminal.white_bright = p.white
end

require("tokyonight").setup({
  style = style,
  cache = false,
  terminal_colors = true,
  on_colors = on_colors,
})

vim.cmd.colorscheme("tokyonight-" .. style)
