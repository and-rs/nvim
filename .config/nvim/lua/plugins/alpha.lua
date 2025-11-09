MiniDeps.now(function()
  MiniDeps.add({ source = "goolord/alpha-nvim" })

  local alpha = require("alpha")
  local dashboard = require("alpha.themes.dashboard")

  local version = function()
    local command = vim.fn.execute("ver")
    local lines = vim.split(command, "\n")
    local second_word = lines[3]:match("^%S+%s+(%S+)")
    return second_word
  end

  local plugin_count = function()
    local dir = vim.fn.stdpath("config") .. "/lua/plugins"
    local count = 0
    for name, t in vim.fs.dir(dir) do
      if t == "file" and name:sub(-4) == ".lua" then
        count = count + 1
      end
    end
    return count
  end

  dashboard.section.header.val = {
    [[│  Neovim ]] .. version(),
    [[│  Currently ]] .. plugin_count() .. [[ plugins installed]],
    [[│  Open source and freely distributable]],
  }
  dashboard.section.footer.val = {
    [[                                    ]],
    [[            .                       ]],
    [[             \\              .,     ]],
    [[              '#\         .*/'      ]],
    [[ .:::##*.      '#\      *#/'        ]],
    [[//'  '':#\      \#.    #/'          ]],
    [['       \*#\     |#.  #/ ./#####::. ]],
    [[          \*#\   |#: #/ /##/      '\]],
    [[       __##-= .=_***$*-. ===._      ]],
    [[  __::::###*.-*$######$*-. =::#*.   ]],
    [[ --/'      .-+*$########$*-.  '::\  ]],
    [[//'       ; .-+*$#######$*-.    ':| ]],
    [['        ;#/  .-+*$####$*-.     ':| ]],
    [[        :#/  .#. '-*##*-'       ':| ]],
    [[       .#|   |#.                :/  ]],
    [[       :|    |#:                '   ]],
    [[       '      |:                    ]],
    [[               \:                   ]],
    [[                '                   ]],
  }

  dashboard.config = {
    layout = {
      { type = "padding", val = 1 },
      dashboard.section.header,
      dashboard.section.footer,
    },
    opts = { margin = 2 },
  }

  dashboard.section.header.opts = {
    position = "left",
    hl = "Statement",
  }

  dashboard.section.footer.opts = {
    position = "center",
  }

  alpha.setup(dashboard.config)
end)
