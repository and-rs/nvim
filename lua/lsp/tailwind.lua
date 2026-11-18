---@type vim.lsp.Config
return {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = vim.list_extend({ "jinja" }, vim.lsp.config.tailwindcss.filetypes),
  settings = {
    tailwindCSS = {
      includeLanguages = {
        jinja = "html",
      },
    },
  },
}
