return {
  "ibhagwan/fzf-lua",
  config = function()
    local fzf = require("fzf-lua")

    require("fzf-lua").setup({
      hls = {
        border = "WinBorder",
        preview_border = "WinBorder",
        header_text = "Comment",
        header_bind = "Comment",
      },
      actions = {
        files = {
          ["ctrl-s"] = fzf.actions.file_vsplit,
          ["ctrl-t"] = fzf.actions.file_tabedit,
          ["alt-q"] = fzf.actions.file_sel_to_qf,
          ["alt-Q"] = fzf.actions.file_sel_to_ll,
          ["alt-i"] = fzf.actions.toggle_ignore,
          ["alt-h"] = fzf.actions.toggle_hidden,
          ["alt-f"] = fzf.actions.toggle_follow,
          ["enter"] = fzf.actions.file_edit_or_qf,
        },
      },
      fzf_colors = {
        --["bg"] = { "bg", "Normal" },
        --["bg+"] = { "bg", "Normal" },
        ["fg"] = { "fg", "Comment" },
        ["fg+"] = { "fg", "Normal" },
        ["hl"] = { "fg", "Special" },
        ["hl+"] = { "fg", "Special" },
        ["info"] = { "fg", "Special" },
        ["prompt"] = { "fg", "Comment" },
        ["pointer"] = { "fg", "Special" },
        ["marker"] = { "fg", "Keyword" },
        ["spinner"] = { "fg", "Label" },
        ["header"] = { "fg", "Comment" },
        ["separator"] = { "fg", "WinBorder" },
        ["scrollbar"] = { "fg", "WinBorder" },
      },
      winopts = {
        border = { "├", "─", "┤", "│", "┘", "─", "└", "│" },
        height = 0.6,
        width = 76,
        row = 0,
        col = 0.5,
        preview = {
          border = { "┌", "─", "┐", "│", "", "", "", "│" },
          layout = "vertical",
          vertical = "up:44%",
          scrollbar = false,
        },
      },
    })

    --keybinds
    local map = function(keys, type, desc)
      local command = function()
        if type == "" then
          require("fzf-lua").builtin({
            winopts = {
              border = "single",
              preview = {
                border = "single",
              },
              height = 0.2,
              width = 40,
              row = 0.4,
              col = 0.48,
            },
          })
        else
          require("fzf-lua")[type]({
            file_icons = false,
            git_icons = false,
            color_icons = false,
          })
        end
      end
      vim.keymap.set("n", keys, command, { desc = desc })
    end

    map("<leader>sa", "", "FZF")
    map("<leader>sf", "files", "Files")
    map("<leader>sh", "help_tags", "Help")
    map("<leader>sb", "buffers", "Buffers")
    map("<leader>sr", "oldfiles", "Recent files")
    map("<leader>sv", "grep_visual", "Grep Visual")
    map("<leader>sc", "grep_cword", "Current Word")
    map("<leader>sg", "live_grep_native", "Grep Word")
    map("<leader>sd", "diagnostics_document", "Diagnostics")

    --lsp
    map("<leader>lr", "lsp_references", "LSP References")
    map("<leader>ld", "lsp_definitions", "LSP Definitions")
    map("<leader>lc", "lsp_code_actions", "LSP Code Actions")
    map("<leader>lt", "lsp_typedefs", "LSP Type Definitions")
    map("<leader>lI", "lsp_implementations", "LSP Implementations")
  end,
}
