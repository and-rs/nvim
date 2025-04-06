return {
  "mfussenegger/nvim-lint",
  lazy = true,
  enabled = false,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      sh = { "shellcheck" },
    }

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

    vim.keymap.set("n", "<leader>ml", function()
      lint.try_lint()
    end, { desc = "Make Linting" })
  end,
}
