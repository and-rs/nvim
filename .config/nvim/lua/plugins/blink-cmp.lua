return {
  "saghen/blink.cmp",
  event = { "CmdlineEnter", "BufNewFile", "BufReadPre" },
  dependencies = {
    "L3MON4D3/LuaSnip",
    dependencies = "rafamadriz/friendly-snippets",
    version = "v2.*",
    init = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  version = "*",
  config = function()
    local cmp = require("blink.cmp")

    local function get_cursor_context()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local line = vim.api.nvim_get_current_line()
      return col, line:sub(1, col)
    end

    local function is_snippet_trigger()
      local _, before_cursor = get_cursor_context()
      return before_cursor:match(";%w*$") ~= nil
    end

    cmp.setup({
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
          lsp = {},

          snippets = {
            name = "SNP",
            enabled = true,
            max_items = 20,
            min_keyword_length = 1,
            module = "blink.cmp.sources.snippets",

            -- Higher number is higher priority
            score_offset = 85,

            -- Only show snippets after ';' character
            should_show_items = function()
              return is_snippet_trigger()
            end,

            transform_items = function(_, items)
              local col, before_cursor = get_cursor_context()
              local trigger_pos = before_cursor:find(";[^;]*$")

              if trigger_pos then
                for _, item in ipairs(items) do
                  item.textEdit = {
                    newText = item.insertText or item.label,
                    range = {
                      start = { line = vim.fn.line(".") - 1, character = trigger_pos - 1 },
                      ["end"] = { line = vim.fn.line(".") - 1, character = col },
                    },
                  }
                end
              end

              -- Reload snippets otherwise it won't work correctly, idk why
              vim.schedule(function()
                require("blink.cmp").reload("snippets")
              end)
              return items
            end,
          },
        },

        -- Filter snippets if they are not triggered
        transform_items = function(_, items)
          if is_snippet_trigger() then
            return items
          end
          return vim.tbl_filter(function(item)
            return item.kind ~= require("blink.cmp.types").CompletionItemKind.Snippet
          end, items)
        end,
      },

      keymap = {
        ["<C-l>"] = { "snippet_forward", "fallback" },
        ["<C-h>"] = { "snippet_backward", "fallback" },
      },

      completion = {
        list = {
          selection = {
            preselect = false,
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 300,
          window = {
            border = { "─", "─", "┐", "│", "┘", "─", "─", " " },
            max_height = 10,
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:WinBorder,EndOfBuffer:BlinkCmpDoc",
          },
        },
        ghost_text = {
          enabled = false,
        },
        menu = {
          draw = {
            components = {

              label = {
                width = { max = 30 },
                text = function(ctx)
                  return ctx.label
                end,
                highlight = "@variable",
              },
              source_name = {
                width = { max = 30 },
                text = function(ctx)
                  return ctx.source_name
                end,
                highlight = "Special",
              },
            },
            columns = {
              { "kind_icon", "label", gap = 2, "source_name" },
            },
          },
          border = "single",
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:WinBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
        },
      },

      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "normal",

        kind_icons = {
          Text = "󰦨",
          Method = "󰊕",
          Function = "󰊕",
          Constructor = "󰒓",

          Field = "󰜢",
          Variable = "󰆦",
          Property = "",

          Class = "󱡠",
          Interface = "󱡠",
          Struct = "󱡠",
          Module = "󰅩",

          Unit = "󰪚",
          Value = "",
          Enum = "",
          EnumMember = "",

          Keyword = "󰌋",
          Constant = "󰏿",

          Snippet = "󰅪",
          Color = "󰏘",
          File = "󰈔",
          Reference = "󰬲",
          Folder = "󰉋",
          Event = "󱐋",
          Operator = "󰪚",
          TypeParameter = "",
        },
      },
    })
  end,
  opts_extend = { "sources.default" },
}
