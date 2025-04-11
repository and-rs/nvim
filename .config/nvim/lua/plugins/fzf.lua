return {
  "ibhagwan/fzf-lua",
  config = function()
    local fzf = require("fzf-lua")

    fzf.setup({
      hls = {
        border = "FloatBorder",
        preview_border = "FloatBorder",
      },
      actions = {
        files = {
          -- ["ctrl-y"] = "--select-1|-q",

          ["ctrl-v"] = fzf.actions.file_vsplit,
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
        ["bg"] = { "bg", "FloatBorder" },
        ["bg+"] = { "bg", "FloatBorder" },

        ["fg"] = { "fg", "Comment" },
        ["fg+"] = { "fg", "Normal" },

        ["hl"] = { "fg", "Special" },
        ["hl+"] = { "fg", "Special" },

        ["spinner"] = { "fg", "Label" },
        ["marker"] = { "fg", "Normal" },
        ["pointer"] = { "fg", "Normal" },
        ["info"] = { "fg", "FloatBorder" },
        ["prompt"] = { "fg", "FloatBorder" },
        ["header"] = { "fg", "FloatBorder" },
        ["separator"] = { "fg", "FloatBorder" },
        ["scrollbar"] = { "fg", "FloatBorder" },
      },
      winopts = {
        border = "single",
        height = 15,
        width = 90,
        row = 0.1,
        col = 0.5,
        preview = {
          hidden = true,
        },
      },
    })

    local builtin_opts = {
      winopts = {
        border = "single",
        preview = {
          border = "single",
        },
        height = 8,
        width = 50,
        row = 0.4,
        col = 0.48,
      },
    }

    local picker_opts = {
      header = false,
      file_icons = false,
      git_icons = false,
      color_icons = false,
    }

    local map = function(keys, picker, desc)
      local command
      if type(picker) == "string" then
        command = function()
          fzf[picker](picker_opts)
        end
      elseif type(picker) == "function" then
        command = picker
      else
        error("Invalid picker type: must be a string or function")
      end
      vim.keymap.set("n", keys, command, { desc = desc })
    end

    local extend = function(table1, table2)
      return vim.tbl_extend("force", table1, table2)
    end

    map("<leader>sa", function()
      fzf.builtin(extend(builtin_opts, picker_opts))
    end, "FZF")

    map("<leader>sf", "files", "Files")
    map("<leader>sh", "help_tags", "Help")
    map("<leader>sb", "buffers", "Buffers")
    map("<leader>sr", "oldfiles", "Recent files")
    map("<leader>sv", "grep_visual", "Grep Visual")
    map("<leader>sc", "grep_cword", "Current Word")
    map("<leader>sg", "live_grep_native", "Grep Word")
    map("<leader>sd", "diagnostics_document", "Diagnostics")

    --lsp
    map("gd", function()
      fzf.lsp_definitions(extend(picker_opts, { jump1 = true }))
    end, "LSP Definitions")

    map("<leader>lr", function()
      fzf.lsp_references(
        extend(picker_opts, { includeDeclaration = false, ignore_current_line = true })
      )
    end, "LSP References")

    map("<leader>lc", "lsp_code_actions", "LSP Code Actions")
    map("<leader>lt", "lsp_typedefs", "LSP Type Definitions")
    map("<leader>lI", "lsp_implementations", "LSP Implementations")
  end,
}
