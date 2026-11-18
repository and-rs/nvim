vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("FiletypeIndentation", { clear = true }),
  pattern = { "cpp", "nu", "qmljs" },
  callback = function(event)
    local bo = vim.bo[event.buf]
    bo.autoindent = false
    bo.smartindent = false
    bo.cindent = false
    bo.lisp = false
    bo.indentexpr = ""
    bo.indentkeys = ""
    bo.expandtab = false
    bo.softtabstop = 0
    bo.tabstop = 2
    bo.shiftwidth = 2
  end,
})
