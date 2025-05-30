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
        build = function()
          local utils = require('core.utils')
          -- Platform-specific build command
          if utils.platform.is_mac() then
            return "make"
          else
            return "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build"
          end
        end,
        cond = function()
          local utils = require('core.utils')
          return utils.platform.command_available("make") or utils.platform.command_available("cmake")
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
} 