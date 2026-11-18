-- Opt in with NVIM_PROFILE=1 or NVIM_PROFILE=start.
local should_profile = os.getenv("NVIM_PROFILE")
if not should_profile or should_profile == "" then
  return
end

vim.pack.add({ "https://github.com/stevearc/profile.nvim" })
local prof = require("profile")

prof.instrument_autocmds()
if should_profile:lower():match("^start") then
  prof.start("*")
else
  prof.instrument("*")
end

local function toggle_profile()
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
