vim.pack.add({ "https://github.com/goolord/alpha-nvim" })

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

local plugin_count = function()
  local dir = vim.fn.stdpath("data") .. "/site/pack/core/opt"
  local count = 0
  for _, type in vim.fs.dir(dir) do
    if type == "directory" then
      count = count + 1
    end
  end
  return count
end

local version_output = vim.fn.execute("ver")
local version_lines = vim.split(version_output, "\n", { trimempty = true })
version_lines[#version_lines] = nil

local prefixed_version = vim.tbl_map(function(line)
  return "│  " .. line
end, version_lines)

dashboard.section.header.val = vim.list_extend(prefixed_version, {
  "│",
  "│  Currently " .. plugin_count() .. " plugins installed",
  "│  Open source and freely distributable",
})

dashboard.section.footer.val = {
  [[                                      ]],
  [[            .                         ]],
  [[             \\              .,       ]],
  [[              '#\         .*/'        ]],
  [[  .:::##*.      '#\      *#/'         ]],
  [[ //'  '':#\      \#.    #/'           ]],
  [[ '       \*#\     |#.  #/ ./#####::.  ]],
  [[           \*#\   |#: #/ /##/      '\ ]],
  [[       __##-= .=_$****$*-. ===._      ]],
  [[  __::::###*.-*$########$*-. =::#*.   ]],
  [[ --/'      .-+*$##########$*-.  '::\  ]],
  [[//'       ; .-+*$#########$*-.    ':| ]],
  [['        ;#/  .-+*$######$*-.     ':| ]],
  [[        :#/  .#. '-*####*-'       ':| ]],
  [[       .#|   |#.                :/    ]],
  [[       :|    |#:                '     ]],
  [[       '      |:                      ]],
  [[               \:                     ]],
  [[                '                     ]],
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
