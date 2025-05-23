-- LSP and completion plugin specifications
-- Contains language server support and autocompletion

return {
  -- Completion engine
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path", 
      "hrsh7th/cmp-cmdline",
    },
    config = function()
      require("plugins.config.cmp").setup()
    end,
  },

  -- Debugging support
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<F5>", "<cmd>DapContinue<cr>", desc = "DAP Continue" },
      { "<leader>db", "<cmd>DapToggleBreakpoint<cr>", desc = "DAP Toggle Breakpoint" },
    },
    cmd = { "DapContinue", "DapToggleBreakpoint" },
    dependencies = {
      "nvim-neotest/nvim-nio",
      {
        "rcarriga/nvim-dap-ui",
        config = function()
          -- DAP UI setup will be handled in dap config
        end,
      },
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      require("plugins.config.dap").setup()
    end,
  },
} 