return {
  "mfussenegger/nvim-lint",
  lazy = true,
  enabled = false,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      sh = { "shellcheck" },
      zsh = { "shellcheck" },
    }

    local function filename_or_stdin()
      local bufname = vim.api.nvim_buf_get_name(0)
      local file = vim.fn.fnameescape(vim.fn.fnamemodify(bufname, ":p"))
      if vim.bo.buftype == "" and vim.fn.filereadable(file) == 1 then
        return file
      end
      return "-"
    end
    lint.linters.shellcheck.args = { "-x", "--format", "json1", filename_or_stdin }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd(
      { "BufReadPre", "BufWritePost", "InsertEnter", "InsertLeave", "TextChanged" },
      {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      }
    )

    -- Diagnostics
    vim.keymap.set("n", "<leader>d", function()
      vim.diagnostic.open_float({ border = "single" })
    end, { desc = "Show line diagnostics" })

    vim.keymap.set("n", "<leader>ml", function()
      lint.try_lint()
    end, { desc = "Make Linting" })
  end,
}
