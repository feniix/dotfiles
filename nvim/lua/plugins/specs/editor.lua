-- Editor enhancement plugin specifications
-- Contains editing tools, navigation, and productivity plugins

return {
  -- Core editorconfig support
  {
    "editorconfig/editorconfig-vim",
    event = "VeryLazy",
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    config = function()
      require("plugins.config.telescope").setup()
    end,
  },

  -- TreeSitter for syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/nvim-treesitter-context",
    },
    config = function()
      require("plugins.config.treesitter").setup()
    end,
  },

  -- TreeSitter context-aware commenting
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
  },

  -- Commenting plugin
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("plugins.config.comment").setup()
    end,
  },

  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("plugins.config.gitsigns").setup()
    end,
  },

  -- Surround text objects
  {
    "kylechui/nvim-surround",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-surround").setup{}
    end,
  },

  -- Whitespace management
  {
    "kaplanz/retrail.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("plugins.config.retrail").setup()
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup{}
    end,
  },

  -- Split/join code constructs
  {
    "AndrewRadev/splitjoin.vim",
    keys = { "gS", "gJ" },
  },

  -- Which-key for key bindings help
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("plugins.config.which-key").setup()
    end,
  },
} 