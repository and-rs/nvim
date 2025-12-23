MiniDeps.now(function()
  MiniDeps.add({ source = "goolord/alpha-nvim" })

  local quickfix_pre = vim.api.nvim_create_augroup("quickfix_pre", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = quickfix_pre,
    pattern = "qf",
    callback = function()
      vim.schedule(function()
        local bufs = vim.api.nvim_list_bufs()
        for _, buf in ipairs(bufs) do
          if vim.api.nvim_buf_is_valid(buf) then
            if vim.bo[buf].filetype == "alpha" then
              vim.api.nvim_buf_delete(buf, { force = true })
            end
          end
        end
      end)
    end,
  })

  local alpha = require("alpha")
  local dashboard = require("alpha.themes.dashboard")

  local version = function()
    local command = vim.fn.execute("ver")
    local lines = vim.split(command, "\n")
    local second_word = lines[3]:match("^%S+%s+(%S+)")
    return second_word
  end

  local plugin_count = function()
    local dir = vim.fn.stdpath("data") .. "/site/pack/deps/opt"
    local count = 0
    for _, type in vim.fs.dir(dir) do
      if type == "directory" then
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
    [[       __##-= .=_****$*-. ===._      ]],
    [[  __::::###*.-*$#######$*-. =::#*.   ]],
    [[ --/'      .-+*$#########$*-.  '::\  ]],
    [[//'       ; .-+*$########$*-.    ':| ]],
    [['        ;#/  .-+*$#####$*-.     ':| ]],
    [[        :#/  .#. '-*###*-'       ':| ]],
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
