local map = require("config.map").set

local function disable_auto_indent(buf)
  vim.bo[buf].autoindent = false
  vim.bo[buf].smartindent = false
  vim.bo[buf].cindent = false
  vim.bo[buf].lisp = false
  vim.bo[buf].indentexpr = ""
  vim.bo[buf].indentkeys = ""
  vim.bo[buf].expandtab = false
  vim.bo[buf].tabstop = 2
  vim.bo[buf].softtabstop = 0
  vim.bo[buf].shiftwidth = 2
end

local M = {}

function M.tidal(buf)
  disable_auto_indent(buf)
  map(
    "n",
    "<leader>tr",
    require("config.music.tidal").send_buffer,
    "Send buffer to Tidal",
    { buffer = buf }
  )
  map("n", "<leader>th", require("config.music.tidal").hush, "Hush Tidal", { buffer = buf })
end

function M.supercollider(buf)
  disable_auto_indent(buf)
  map(
    "x",
    "<leader>tr",
    require("config.music.supercollider").send_selection,
    "Evaluate selection in SuperCollider",
    { buffer = buf }
  )
end

return M
