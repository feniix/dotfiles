-- UI-related plugin specifications
-- Contains colorschemes, statuslines, and visual enhancements

return {
  -- NeoSolarized theme
  {
    "svrana/neosolarized.nvim",
    dependencies = { "tjdevries/colorbuddy.nvim" },
    lazy = false,
    priority = 1000,
    config = function()
      require("plugins.config.colorscheme").setup()
    end,
  },
  
  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    config = function()
      require("plugins.config.indent-blankline").setup()
    end,
  },

  -- File icons
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("plugins.config.lualine").setup()
    end,
  },

  -- Rainbow parentheses
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("plugins.config.rainbow-delimiters").setup()
    end,
  },

  -- TODO comments highlighting
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("plugins.config.todo-comments").setup()
    end,
  },
} 