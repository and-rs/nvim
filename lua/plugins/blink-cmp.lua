MiniDeps.now(function()
  MiniDeps.add({
    source = "saghen/blink.cmp",
    depends = {
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
    },
    checkout = "v1.7.0",
  })
end)

MiniDeps.later(function()
  -- event = { "CmdlineEnter", "InsertEnter" },
  -- create load event

  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_vscode").lazy_load({
    paths = "~/.config/nvim/snippets",
  })

  require("blink.cmp").setup({
    enabled = function()
      local filetype = vim.bo[0].filetype == "fzf"
      return filetype and false or true
    end,

    snippets = {
      preset = "luasnip",
    },

    sources = {
      default = { "lsp", "snippets", "path", "buffer" },
      providers = {
        path = {
          name = "PATH",
        },
        cmdline = {
          name = "CMD",
        },
        buffer = {
          name = "BUF",
        },
        lsp = {
          name = "LSP",
        },
        snippets = {
          name = "SNP",
          score_offset = -20,
        },
      },
    },

    keymap = {
      ["<C-l>"] = { "snippet_forward", "fallback" },
      ["<C-h>"] = { "snippet_backward", "fallback" },
      ["<C-t>"] = {
        function(list)
          list.show()
        end,
      },
    },

    completion = {
      list = {
        max_items = 20,
        selection = {
          preselect = false,
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 100,
        window = {
          border = "rounded",
          max_height = 10,
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:FloatBorder,EndOfBuffer:BlinkCmpDoc",
        },
      },
      ghost_text = {
        enabled = false,
      },
      menu = {
        draw = {
          components = {
            label = {
              width = { max = 22 },
              text = function(ctx)
                return ctx.label
              end,
              highlight = "Special",
            },
            kind = {
              text = function(ctx)
                return ctx.kind .. " :"
              end,
              highlight = "None",
            },
            source_name = {
              width = { max = 3 },
              text = function(ctx)
                return ctx.source_name
              end,
              highlight = "None",
            },
          },
          columns = {
            { "source_name", gap = 1 },
            { "kind" },
            { "label" },
          },
        },
        border = "rounded",
        winhighlight = "Normal:BlinkCmpDoc,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None,BlinkCmpKind:None",
      },
    },

    appearance = {
      use_nvim_cmp_as_default = false,
    },
  })
end)
