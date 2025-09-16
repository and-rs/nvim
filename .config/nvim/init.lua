require("config.settings")
require("config.keymaps")
require("config.lazy")

require("utils.highlights")
require("utils.tailwind")

-- local filetree = require("utils.filetree")
--
-- filetree.setup({
--   mode = "keep",
-- })
--
-- vim.keymap.set("n", "<leader>fe", function()
--   filetree.toggle()
-- end, { desc = "Toggle file tree" })

if vim.g.neovide then
  vim.o.guifont = "Input Mono,Symbols Nerd Font Mono:h12"
  vim.opt.linespace = 3
  vim.g.neovide_show_border = true
  vim.g.neovide_scroll_animation_lenght = 0.1
end

local should_profile = os.getenv("NVIM_PROFILE")
if should_profile then
  require("profile").instrument_autocmds()
  if should_profile:lower():match("^start") then
    require("profile").start("*")
  else
    require("profile").instrument("*")
  end
end

local function toggle_profile()
  local prof = require("profile")
  if prof.is_recording() then
    prof.stop()
    vim.ui.input(
      { prompt = "Save profile to:", completion = "file", default = "profile.json" },
      function(filename)
        if filename then
          prof.export(filename)
          vim.notify(string.format("Wrote %s", filename))
        end
      end
    )
  else
    prof.start("blink*")
  end
end
vim.keymap.set("", "<f1>", toggle_profile)
