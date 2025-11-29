MiniDeps.now(function()
  MiniDeps.add({ source = "ibhagwan/fzf-lua" })

  local fzf = require("fzf-lua")
  fzf.register_ui_select()

  fzf.setup({
    hls = {
      title = "FloatBorder",
      border = "FloatBorder",
      preview_border = "FloatBorder",
      preview_normal = "FloatBorder",
      preview_title = "FloatBorder",
    },
    oldfiles = {
      cwd_only = true,
    },
    keymap = {
      fzf = {
        ["ctrl-y"] = "toggle+down",
        ["ctrl-i"] = "up+toggle",
        ["ctrl-f"] = "page-down",
        ["ctrl-b"] = "page-up",
        ["ctrl-d"] = "half-page-down",
        ["ctrl-u"] = "half-page-up",
      },
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
      ["bg+"] = { "bg", "Normal" },

      ["border"] = { "fg", "FloatBorder" },
      ["separator"] = { "fg", "Normal" },
      ["scrollbar"] = { "fg", "Normal" },

      ["fg"] = { "fg", "Comment" },
      ["fg+"] = { "fg", "PreProc" },

      ["hl"] = { "fg", "Constant" },
      ["hl+"] = { "fg", "Constant" },

      ["spinner"] = { "fg", "Label" },
      ["marker"] = { "fg", "PreProc" },
      ["pointer"] = { "fg", "PreProc" },

      ["prompt"] = { "fg", "Special" },
      ["info"] = { "fg", "Special" },
    },
    winopts = {
      border = "rounded",
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
      border = "rounded",
      preview = {
        border = "rounded",
      },
      height = 10,
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

  local function dynamic_width()
    return math.min(76, vim.o.columns - 4)
  end

  local function extend(t1, t2)
    return vim.tbl_extend("force", t1, t2)
  end

  local fzf_dynamic = setmetatable({}, {
    __index = function(_, k)
      local orig = fzf[k]
      if type(orig) ~= "function" then
        return orig
      end
      return function(opts)
        opts = opts or {}
        if k ~= "builtin" then
          opts.winopts = extend(opts.winopts or {}, { width = dynamic_width() })
        end
        return orig(opts)
      end
    end,
  })

  local function map(keys, picker, desc, mode)
    local command
    if type(picker) == "string" then
      command = function()
        fzf_dynamic[picker](picker_opts)
      end
    elseif type(picker) == "function" then
      command = picker
    else
      error("Invalid picker type: must be a string or function")
    end
    vim.keymap.set(mode or "n", keys, command, { desc = desc })
  end

  map("<leader>sa", function()
    fzf_dynamic.builtin(extend(builtin_opts, picker_opts))
  end, "FZF")

  map("<leader>sf", function()
    fzf_dynamic.files(extend(picker_opts, {
      cmd = "rg --files --hidden --ignore --glob='!.git' --sortr=modified",
      fzf_opts = { ["--scheme"] = "path", ["--tiebreak"] = "index" },
    }))
  end, "Files")

  map("<leader>sr", function()
    fzf_dynamic.oldfiles(extend(picker_opts, { include_current_session = true }))
  end, "Recent files")

  map("gd", function()
    fzf_dynamic.lsp_definitions(extend(picker_opts, { jump1 = true }))
  end, "LSP Definitions")

  map("<leader>lr", function()
    fzf_dynamic.lsp_references(extend(picker_opts, {
      includeDeclaration = false,
      ignore_current_line = true,
    }))
  end, "LSP References")

  map("<C-e>", function()
    require("fzf-lua.win").toggle_fullscreen()
    require("fzf-lua.win").toggle_preview()
  end, "Toggle FZF fullscreen", "t")

  map("<leader>sh", "help_tags", "Help")
  map("<leader>sb", "buffers", "Buffers")
  map("<leader>sv", "grep_visual", "Grep Visual")
  map("<leader>sc", "grep_cword", "Current Word")
  map("<leader>sg", "live_grep_native", "Grep Word")
  map("<leader>sd", "diagnostics_document", "Diagnostics")
  map("<leader>lc", "lsp_code_actions", "LSP Code Actions")
  map("<leader>lt", "lsp_typedefs", "LSP Type Definitions")
  map("<leader>lI", "lsp_implementations", "LSP Implementations")
end)
