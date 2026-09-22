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

local color = require("config.coloring")
local function match_title_to_border()
  color.set("FFFTitle", { link = "FloatBorder" })
end
match_title_to_border()
vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = color.augroup,
  callback = match_title_to_border,
})

require("fff").setup({
  prompt = "> ",
  lazy_sync = true,
  title = "Files",
  preview = { enabled = false },
  hl = { title = "FFFTitle" },
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
