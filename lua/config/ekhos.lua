local group = vim.api.nvim_create_augroup("Ekhos", { clear = true })
local warned = false

local function player_command(path)
  local sysname = vim.uv.os_uname().sysname
  if sysname == "Linux" then
    return { "pw-play", "--latency", "25ms", "--volume", "3", path }
  end
  if sysname == "Darwin" then
    return { "afplay", "--volume", "2", path }
  end
  if sysname == "Windows_NT" then
    return {
      "powershell.exe",
      "-NoProfile",
      "-NonInteractive",
      "-Command",
      "$player = [System.Media.SoundPlayer]::new($args[0]); $player.PlaySync()",
      path,
    }
  end
end

local probe = player_command("")
if not probe then
  vim.notify("Ekhos does not support " .. vim.uv.os_uname().sysname, vim.log.levels.WARN)
  return
end
if vim.fn.executable(probe[1]) ~= 1 then
  vim.notify("Ekhos player missing: " .. probe[1], vim.log.levels.WARN)
  return
end

local function play(cue)
  local path = vim.fn.stdpath("config") .. "/ekhos/zig-out/sounds/" .. cue .. ".wav"
  if vim.fn.filereadable(path) ~= 1 then
    if not warned then
      warned = true
      vim.notify("Ekhos sound missing: run `cd ekhos && zig build`", vim.log.levels.WARN)
    end
    return
  end

  vim.fn.jobstart(player_command(path), { detach = true })
end

vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = group,
  pattern = { ":", "/", "?" },
  callback = function(event)
    play(event.match == ":" and "scan" or "bloom")
  end,
})

local function is_visual(mode)
  local first = mode:sub(1, 1)
  return first == "v" or first == "V" or first == "\22"
end

vim.api.nvim_create_autocmd("ModeChanged", {
  group = group,
  callback = function(event)
    local old_mode, new_mode = event.match:match("^(.-):(.*)$")
    if old_mode and is_visual(old_mode) ~= is_visual(new_mode) then
      play("toggle")
    end
  end,
})

vim.api.nvim_create_autocmd("QuitPre", {
  group = group,
  callback = function()
    play("release")
  end,
})
