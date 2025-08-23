return {
  "goolord/alpha-nvim",
  enabled = true, -- Ensure the plugin is enabled
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    local version = function()
      local command = vim.fn.execute("ver")
      local lines = vim.split(command, "\n")
      local second_word = lines[3]:match("^%S+%s+(%S+)")
      return second_word
    end

    dashboard.section.header.val = {
      [[│  Neovim ]] .. version(),
      [[│  Open source and freely distributable]],
      [[│                                      ]],
      [[│              .                       ]],
      [[│               \\              .,     ]],
      [[│                '#\         .*/'      ]],
      [[│   .:::##*.      '#\      *#/'        ]],
      [[│  //'  '':#\      \#.    #/'          ]],
      [[│  '       \*#\     |#.  #/ ./#####::. ]],
      [[│            \*#\   |#: #/ /##/      '\]],
      [[│         __##-= .=_***$*-. ===._      ]],
      [[│    __::::###*.-*$######$*-. =::#*.   ]],
      [[│   --/'      .-+*$########$*-.  '::\  ]],
      [[│  //'       ; .-+*$#######$*-.    ':| ]],
      [[│  '        ;#/  .-+*$####$*-.     ':| ]],
      [[│          :#/  .#. '-*##*-'       ':| ]],
      [[│         .#|   |#.                :/  ]],
      [[│         :|    |#:                '   ]],
      [[│         '      |:                    ]],
      [[│                 \:                   ]],
      [[│                  '                   ]],
    }

    dashboard.config = {
      layout = {
        { type = "padding", val = 2 },
        dashboard.section.header,
      },
      opts = { margin = 2 },
    }

    dashboard.section.header.opts = {
      position = "left",
      hl = "Special",
    }

    alpha.setup(dashboard.config)
  end,
}
