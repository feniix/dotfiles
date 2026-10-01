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
    -- Declared here, not in config(), so the mappings exist before the
    -- plugin loads; the first press loads diffview (and its config() defines
    -- the DiffviewOpenMain/Master/Staged commands).
    keys = {
      { "<leader>gd", ":DiffviewOpen<CR>", desc = "Open Git diff view", silent = true },
      { "<leader>gh", ":DiffviewFileHistory<CR>", desc = "Open Git file history", silent = true },
      { "<leader>gH", ":DiffviewFileHistory %<CR>", desc = "Open current file history", silent = true },
      { "<leader>gq", ":DiffviewClose<CR>", desc = "Close Git diff view", silent = true },
      { "<leader>gm", ":DiffviewOpenMain<CR>", desc = "Diff against origin/main", silent = true },
      { "<leader>gM", ":DiffviewOpenMaster<CR>", desc = "Diff against origin/master", silent = true },
      { "<leader>gS", ":DiffviewOpenStaged<CR>", desc = "View staged changes", silent = true },
      { "<leader>gh", ":DiffviewFileHistory<CR>", mode = "v", desc = "File history for selection", silent = true },
    },
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