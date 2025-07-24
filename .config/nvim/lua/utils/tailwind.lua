local tailwind = {}

function tailwind.sort()
  vim.cmd([[normal va"vF"]])

  local line_start = vim.fn.getpos("'<")
  local line_end = vim.fn.getpos("'>")

  local row_start = line_start[2] - 1
  local row_end = line_end[2]
  local col_start = line_start[3]
  local col_end = line_end[3]

  local lines = table.concat(vim.api.nvim_buf_get_lines(0, row_start, row_end, true))
  local selection = lines:sub(col_start, col_end)

  if selection:find("%b[]") then
    vim.notify("Rustywind error: Cannot sort due to arbitrary classes", vim.log.levels.ERROR)
    return
  end

  local shell_cmd = "echo "
    .. vim.fn.shellescape("className=" .. selection)
    .. " | rustywind --stdin"

  local output = vim.fn.system(shell_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Error running rustywind: " .. output, vim.log.levels.ERROR)
    return
  end

  local result = output:gsub("\n", ""):gsub("className=", ""):gsub('%b".-"', "")

  vim.api.nvim_buf_set_text(0, row_start, col_start - 1, row_start, col_end, { result })

  vim.notify("Classes sorted successfully", vim.log.levels.INFO)
end

tailwind.lsp = {
  settings = {
    tailwindCSS = {
      includeLanguages = {
        jinja = "html",
        eelixir = "html-eex",
        elixir = "phoenix-heex",
        eruby = "erb",
        heex = "phoenix-heex",
        htmlangular = "html",
        templ = "html",
      },
    },
  },
  filetypes = {
    "jinja", -- this is real good
    -- html
    "aspnetcorerazor",
    "astro",
    "astro-markdown",
    "blade",
    "clojure",
    "django-html",
    "htmldjango",
    "edge",
    "eelixir", -- vim ft
    "elixir",
    "ejs",
    "erb",
    "eruby", -- vim ft
    "gohtml",
    "gohtmltmpl",
    "haml",
    "handlebars",
    "hbs",
    "html",
    "htmlangular",
    "html-eex",
    "heex",
    "jade",
    "leaf",
    "liquid",
    "markdown",
    "mdx",
    "mustache",
    "njk",
    "nunjucks",
    "php",
    "razor",
    "slim",
    "twig",
    -- css
    "css",
    "less",
    "postcss",
    "sass",
    "scss",
    "stylus",
    "sugarss",
    -- js
    "javascript",
    "javascriptreact",
    "reason",
    "rescript",
    "typescript",
    "typescriptreact",
    -- mixed
    "vue",
    "svelte",
    "templ",
  },
  root_dir = function(fname)
    local root_file = {
      "static/input.css", -- this way tailwind will work with a custom css setup
      "tailwind.config.js",
      "tailwind.config.cjs",
      "tailwind.config.mjs",
      "tailwind.config.ts",
      "postcss.config.js",
      "postcss.config.cjs",
      "postcss.config.mjs",
      "postcss.config.ts",
      -- Django
      "theme/static_src/tailwind.config.js",
      "theme/static_src/tailwind.config.cjs",
      "theme/static_src/tailwind.config.mjs",
      "theme/static_src/tailwind.config.ts",
      "theme/static_src/postcss.config.js",
    }
    local util = require("lspconfig.util")
    root_file = util.insert_package_json(root_file, "tailwindcss", fname)
    return util.root_pattern(unpack(root_file))(fname)
  end,
}

vim.keymap.set("n", "<leader>mt", tailwind.sort, { desc = "Sort Inline Tailwind Classes" })

return tailwind
