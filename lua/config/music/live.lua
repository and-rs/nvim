local M = {}

local state = { tab = nil, return_tab = nil, supercollider_win = nil, tidal_win = nil }

local function notify_missing()
  local missing = {}
  if vim.fn.executable("sclang") ~= 1 then
    table.insert(missing, "sclang")
  end
  if vim.fn.executable("tidal") ~= 1 then
    table.insert(missing, "tidal")
  end

  if #missing == 0 then
    return false
  end

  vim.notify(
    "Live tab requires " .. table.concat(missing, " and ") .. " on Neovim's PATH.",
    vim.log.levels.ERROR
  )
  return true
end

local function window_in_tab(win, tab)
  return win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_tabpage(win) == tab
end

local function ensure_windows()
  local tab = state.tab
  local supercollider_valid = window_in_tab(state.supercollider_win, tab)
  local tidal_valid = window_in_tab(state.tidal_win, tab)

  if supercollider_valid and tidal_valid then
    return
  end

  vim.api.nvim_set_current_tabpage(tab)

  if supercollider_valid then
    vim.api.nvim_set_current_win(state.supercollider_win)
    vim.cmd("rightbelow vsplit")
    state.tidal_win = vim.api.nvim_get_current_win()
  elseif tidal_valid then
    vim.api.nvim_set_current_win(state.tidal_win)
    vim.cmd("leftabove vsplit")
    state.supercollider_win = vim.api.nvim_get_current_win()
  else
    state.supercollider_win = vim.api.nvim_tabpage_list_wins(tab)[1]
    vim.api.nvim_set_current_win(state.supercollider_win)
    vim.cmd("rightbelow vsplit")
    state.tidal_win = vim.api.nvim_get_current_win()
  end
end

local function start_processes()
  require("config.music.supercollider").start(state.supercollider_win)
  require("config.music.tidal").start(state.tidal_win)
  vim.api.nvim_set_current_win(state.supercollider_win)
end

local function create_tab(return_tab)
  if notify_missing() then
    return
  end

  state.return_tab = return_tab
  vim.cmd("tabnew")
  state.tab = vim.api.nvim_get_current_tabpage()
  state.supercollider_win = vim.api.nvim_get_current_win()
  vim.cmd("rightbelow vsplit")
  state.tidal_win = vim.api.nvim_get_current_win()

  start_processes()
end

function M.toggle()
  local current_tab = vim.api.nvim_get_current_tabpage()

  if not state.tab or not vim.api.nvim_tabpage_is_valid(state.tab) then
    create_tab(current_tab)
    return
  end

  if current_tab == state.tab then
    if
      state.return_tab
      and vim.api.nvim_tabpage_is_valid(state.return_tab)
      and state.return_tab ~= state.tab
    then
      vim.api.nvim_set_current_tabpage(state.return_tab)
    elseif #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd("tabprevious")
    end
    return
  end

  state.return_tab = current_tab
  vim.api.nvim_set_current_tabpage(state.tab)
  ensure_windows()
  start_processes()
end

return M
