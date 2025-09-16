return {
  "antosha417/nvim-lsp-file-operations",
  event = { "BufReadPre", "BufNewFile" },
  enabled = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-neo-tree/neo-tree.nvim",
  },
  config = function()
    require("lsp-file-operations").setup()
    local lspconfig = require("lspconfig")

    -- Set global defaults for all servers
    lspconfig.util.default_config = vim.tbl_extend("force", lspconfig.util.default_config, {
      capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        -- returns configured operations if setup() was already called
        -- or default operations if not
        require("lsp-file-operations").default_capabilities()
      ),
    })
  end,
}
