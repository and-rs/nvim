return {
  "saghen/blink.cmp",
  lazy = false,
  enabled = true,
  event = { "CmdlineEnter", "InsertEnter" },
  dependencies = {
    "L3MON4D3/LuaSnip",
    dependencies = "rafamadriz/friendly-snippets",
    version = "v2.*",
    init = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_vscode").lazy_load({
        paths = "~/.config/nvim/snippets",
      })
    end,
  },
  version = "*",
  config = function()
    local cmp = require("blink.cmp")
    local trigger_text = ";"

    cmp.setup({
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
            async = false,
            timeout_ms = 0,
            max_items = 20,
          },

          snippets = {
            score_offset = 85,
            min_keyword_length = 2,
            module = "blink.cmp.sources.snippets",
            should_show_items = function()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = vim.api.nvim_get_current_line():sub(1, col)
              return before_cursor:match(trigger_text .. "%w*$") ~= nil
            end,
            transform_items = function(_, items)
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              local start_pos, end_pos =
                before_cursor:find(trigger_text .. "[^" .. trigger_text .. "]*$")
              if start_pos then
                for _, item in ipairs(items) do
                  if not item.trigger_text_modified then
                    ---@diagnostic disable-next-line: inject-field
                    item.trigger_text_modified = true
                    item.textEdit = {
                      newText = item.insertText or item.label,
                      range = {
                        start = { line = vim.fn.line(".") - 1, character = start_pos - 1 },
                        ["end"] = { line = vim.fn.line(".") - 1, character = end_pos },
                      },
                    }
                  end
                end
              end
              return items
            end,
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
          auto_show_delay_ms = 200,
          window = {
            border = "single",
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
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
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
