return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },

  config = function()
    local gitsigns = require("gitsigns")
    gitsigns.setup()

    local function map(mode, l, r, opts)
      opts = opts or {}
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end)

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end)

    -- Actions
    map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Stage Hunk" })
    map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Reset Hunk" })
    map("v", "<leader>gs", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, { desc = "Stage selection" })
    map("v", "<leader>gr", function()
      gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, { desc = "Reset selection" })

    map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Stage Buffer" })
    map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "Reset Buffer" })
    map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "Preview Hunk" })

    map("n", "<leader>gb", gitsigns.toggle_current_line_blame, { desc = "Toggle Blame Line" })

    map("n", "<leader>gd", function()
      gitsigns.diffthis("~", { vertical = true, split = "botright" })
    end, { desc = "Show Diff" })

    map("n", "<leader>gx", gitsigns.preview_hunk_inline, { desc = "Toggle Deleted" })

    -- Text object
    map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select Hunk" })
  end,
}
