local group = vim.api.nvim_create_augroup("Ekhos", { clear = true })
local warned = false

local function player_command(path, volume)
  local sysname = vim.uv.os_uname().sysname
  if sysname == "Linux" then
    return {
      "pw-play",
      "--media-type",
      "Audio",
      "--media-category",
      "Playback",
      "--media-role",
      "Event",
      "--latency",
      "25ms",
      "--volume",
      volume,
      path,
    }
  end
  if sysname == "Darwin" then
    return { "afplay", "--volume",volume, path }
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

---@param cue string
---@param volume string | nil
local function play(cue, volume)
  local path = vim.fn.stdpath("config") .. "/ekhos/zig-out/sounds/" .. cue .. ".wav"
  local vol = volume or "2"
  if vim.fn.filereadable(path) ~= 1 then
    if not warned then
      warned = true
      vim.notify("Ekhos sounds missing: run `just bootstrap`", vim.log.levels.WARN)
    end
    return
  end
  vim.fn.jobstart(player_command(path, vol), { detach = true })
end

local function is_visual(mode)
  local first = mode:sub(1, 1)
  return first == "v" or first == "V" or first == "\22"
end

-- arrival.wav
-- bloom.wav
-- chime.wav
-- droplet.wav
-- error.wav
-- loading.wav
-- page.wav
-- press.wav
-- pulse.wav
-- ready.wav
-- release.wav
-- scan.wav
-- sparkle.wav
-- success.wav
-- tick.wav
-- toggle.wav
-- whisper.wav

vim.api.nvim_create_autocmd("ModeChanged", {
  group = group,
  callback = function(event)
    local old_mode, new_mode = event.match:match("^(.-):(.*)$")
    if new_mode:sub(1, 1) == "c" and old_mode:sub(1, 1) ~= "c" then
      local cmdtype = vim.fn.getcmdtype()
      play(cmdtype == ":" and "scan" or "bloom")
    elseif old_mode and is_visual(old_mode) ~= is_visual(new_mode) then
      play("tick", "1")
    end
  end,
})
