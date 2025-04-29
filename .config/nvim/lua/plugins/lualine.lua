local function lint_progress()
  local linters = require("lint").get_running()
  if #linters == 0 then
    return ""
  end
  return " " .. table.concat(linters, ", ")
end

local function harpoon()
  local mark = ""
  if package.loaded["harpoon"] then
    local current_file = vim.fn.expand("%:p")

    for id, item in ipairs(require("harpoon"):list().items) do
      local item_file = vim.fn.fnamemodify(item.value, ":p")

      if item_file == current_file then
        mark = id .. " "
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

return {
  "nvim-lualine/lualine.nvim",
  config = function()
    local colors = {
      white = Get_hl_hex("PreProc", "fg"),
      border = Get_hl_hex("Conceal", "fg"),
      background = Get_hl_hex("StatusLineNc", "bg"),
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
          {
            "filename",
            path = 0,
            symbols = {
              modified = " ",
              readonly = "",
              unnamed = "No name",
              newfile = "New file",
            },
          },
          { "branch", icon = { "", align = "right" } },
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
          "vim.bo.filetype",
          { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
        },
      },

      options = {
        icons_enabled = true,
        globalstatus = true,
        disabled_filetypes = { "alpha" },
        component_separators = " │ ",
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
