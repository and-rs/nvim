return {
  "ibhagwan/fzf-lua",
  config = function()
    local fzf = require("fzf-lua")
    fzf.register_ui_select()

    fzf.setup({
      hls = {
        prompt = "Constant",
        title = "FloatBorder",
        border = "FloatBorder",
        preview_border = "FloatBorder",
      },
      keymap = {
        fzf = { ["ctrl-y"] = "toggle+down", ["ctrl-i"] = "up+toggle" },
      },
      actions = {
        files = {
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
        ["fg+"] = { "fg", "PreProc" },

        ["hl"] = { "fg", "Constant" },
        ["hl+"] = { "fg", "Constant" },

        ["spinner"] = { "fg", "Label" },
        ["marker"] = { "fg", "PreProc" },
        ["pointer"] = { "fg", "PreProc" },

        ["prompt"] = { "fg", "Special" },
        ["info"] = { "fg", "Special" },

        ["header"] = { "fg", "Normal" },
        ["separator"] = { "fg", "Normal" },
        ["scrollbar"] = { "fg", "Normal" },
      },
      winopts = {
        border = "single",
        height = 15,
        width = 76,
        row = 0.2,
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

    local map = function(keys, picker, desc, mode)
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
      vim.keymap.set(mode and mode or "n", keys, command, { desc = desc })
    end

    local extend = function(table1, table2)
      return vim.tbl_extend("force", table1, table2)
    end

    map("<leader>sa", function()
      fzf.builtin(extend(builtin_opts, picker_opts))
    end, "FZF")

    map("<leader>sf", function()
      fzf.files(extend(picker_opts, {
        cmd = "rg --files --hidden --ignore --glob='!.git' --sortr=modified",
        fzf_opts = { ["--scheme"] = "path", ["--tiebreak"] = "index" },
      }))
    end, "Files")

    map("<leader>sh", "help_tags", "Help")
    map("<leader>sb", "buffers", "Buffers")
    map("<leader>sr", function()
      fzf.oldfiles(extend(picker_opts, { include_current_session = true }))
    end, "Recent files")
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

    --util
    map("<C-e>", function()
      require("fzf-lua.win").toggle_fullscreen()
      require("fzf-lua.win").toggle_preview()
    end, "Toggle FZF fullscreen", { "c", "i", "t" })
  end,
}
