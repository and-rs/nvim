vim.pack.add({ "https://github.com/saghen/blink.lib" })

local function load()
  vim.pack.add({
    "https://github.com/L3MON4D3/LuaSnip",
    "https://github.com/rafamadriz/friendly-snippets",
    { src = "https://github.com/saghen/blink.cmp" },
  })

  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_vscode").lazy_load({
    paths = "~/.config/nvim/snippets",
  })

  local cmp = require("blink.cmp")
  local kinds = require("blink.cmp.types").CompletionItemKind

  local function lsp_kind_priority(kind)
    if kind == kinds.Property then return 1 end
    if kind == kinds.Method then return 3 end
    return 2
  end

  cmp.build():wait(600)
  cmp.setup({
    enabled = function()
      local filetype = vim.bo[0].filetype == "fzf"
      return filetype and false or true
    end,

    snippets = {
      preset = "luasnip",
    },

    sources = {
      default = { "lsp", "path", "buffer" },
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
          score_offset = 1,
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
      ["^"] = {
        function(blink)
          return blink.show({ providers = { "snippets" } })
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

    fuzzy = {
      sorts = {
        function(a, b)
          if a.source_id ~= "lsp" or b.source_id ~= "lsp" then return end

          local priority_a = lsp_kind_priority(a.kind)
          local priority_b = lsp_kind_priority(b.kind)

          if priority_a == priority_b then return end
          return priority_a < priority_b
        end,
        "score",
        "sort_text",
      },
    },

    appearance = {
      use_nvim_cmp_as_default = false,
    },
  })
end

vim.schedule(function()
  vim.api.nvim_create_autocmd({ "CmdlineEnter", "InsertEnter" }, {
    group = Deferred_group,
    once = true,
    callback = load,
  })
end)
