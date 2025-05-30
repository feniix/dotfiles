-- Development tools and utilities
-- Plugin specifications for development workflow tools

return {
  -- Git interface
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    cmd = { "Git", "Gstatus", "Gblame", "Gpush", "Gpull" },
  },

  -- Git signs (git integration in sign column)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cond = function()
      local utils = require('core.utils')
      return utils.platform.command_available("git")
    end,
    opts = {},
    config = function()
      require("plugins.config.gitsigns").setup()
    end,
  },

  -- Better diff viewing
  {
    "sindrets/diffview.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    config = function()
      require("plugins.config.diffview").setup()
    end,
  },

  -- Plugin management tools and utilities
  {
    "folke/lazy.nvim",
    lazy = false,
    config = function()
      require("plugins.config.tools").setup()
    end,
  },
} 