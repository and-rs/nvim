vim.pack.add({
  { src = "file:///home/and-rs/Vault/dev/exoskeleton", name = "exoskeleton.nvim" },
})

local map = require("config.map").set

-- map("t", "<Esc>", [[<C-\><C-n>]])
map("n", "<leader>au", function()
  vim.pack.update({ "exoskeleton.nvim" }, { force = true })
  vim.cmd("restart")
end, "Update Exo plugin")
map("n", "<leader>ai", ":ExoskeletonPiOpen<CR>", "Open Pi")
map("n", "<leader>ae", ":ExoskeletonPiToggle<CR>", "Open Pi")
