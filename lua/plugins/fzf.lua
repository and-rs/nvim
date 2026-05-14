vim.pack.add({ "https://github.com/ibhagwan/fzf-lua" })

local fzf = require("fzf-lua")
fzf.register_ui_select()

local function get_opts(opts)
  opts = opts or {}
  opts.winopts = opts.winopts or {}
  opts.winopts.row = 0.25
  opts.winopts.height = math.floor(vim.o.lines / 2)
  opts.winopts.width = math.min(74, vim.o.columns - 4)
  opts.winopts.backdrop = 100
  return opts
end

fzf.setup({
  keymap = {
    fzf = {
      ["ctrl-i"] = "up+toggle",
      ["ctrl-y"] = "toggle+down",
      ["ctrl-b"] = "page-up",
      ["ctrl-f"] = "page-down",
      ["ctrl-u"] = "half-page-up",
      ["ctrl-d"] = "half-page-down",
      ["ctrl-alt-h"] = "unix-line-discard",
    },
  },
  actions = {
    files = {
      ["ctrl-t"] = fzf.actions.file_tabedit,
      ["alt-q"] = fzf.actions.file_sel_to_qf,
      ["alt-Q"] = fzf.actions.file_sel_to_ll,
      ["alt-i"] = fzf.actions.toggle_ignore,
      ["alt-h"] = fzf.actions.toggle_hidden,
      ["alt-f"] = fzf.actions.toggle_follow,
      ["enter"] = fzf.actions.file_edit_or_qf,
    },
  },
  winopts = {
    border = "rounded",
    height = 15,
    width = 76,
    row = 0.2,
    col = 0.5,
    preview = { hidden = true, winopts = { number = false } },
  },
})

local map = vim.keymap.set

map("n", "<leader>sr", function()
  fzf.files(get_opts({
    cmd = "rg --files --hidden --ignore --glob='!.git' --glob='!.obsidian'",
    fzf_opts = { ["--scheme"] = "path" },
    cwd_prompt = false,
  }))
end, { desc = "Files" })

map("n", "<leader>sg", function()
  fzf.live_grep_native(get_opts({
    no_header = true,
    no_header_i = true,
    rg_glob = false,
    rg_opts = "--hidden --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
  }))
end, { desc = "Grep Word" })

map("v", "<leader>sv", function()
  fzf.grep_visual(get_opts())
end, { desc = "Grep visual" })

map("t", "<C-e>", function()
  require("fzf-lua.win").toggle_fullscreen()
  require("fzf-lua.win").toggle_preview()
end, { desc = "Toggle FZF Preview", noremap = true })

map("n", "<leader>sa", function()
  fzf.builtin(get_opts())
end, { desc = "FZF Builtin" })
map("n", "<leader>sh", function()
  fzf.help_tags(get_opts())
end, { desc = "Help" })
map("n", "<leader>sb", function()
  fzf.buffers(get_opts({
    no_header = true,
    no_header_i = true,
  }))
end, { desc = "Buffers" })
map("n", "<leader>sd", function()
  fzf.diagnostics_document(get_opts())
end, { desc = "Diagnostics" })
map("n", "gd", function()
  fzf.lsp_definitions(get_opts({ jump1 = true }))
end, { desc = "LSP Def" })
map("n", "<leader>lr", function()
  fzf.lsp_references(get_opts({ includeDeclaration = false, ignore_current_line = true }))
end, { desc = "LSP Ref" })
map("n", "<leader>lc", function()
  fzf.lsp_code_actions(get_opts())
end, { desc = "LSP Actions" })
map("n", "<leader>lt", function()
  fzf.lsp_typedefs(get_opts())
end, { desc = "LSP Type Def" })
map("n", "<leader>lI", function()
  fzf.lsp_implementations(get_opts())
end, { desc = "LSP Imp" })
