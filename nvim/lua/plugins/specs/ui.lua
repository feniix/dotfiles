-- UI-related plugin specifications
-- Contains colorschemes, statuslines, and visual enhancements

return {
  -- Catppuccin colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- latte, frappe, macchiato, mocha
        background = { -- :h background
          light = "latte",
          dark = "mocha",
        },
        transparent_background = false,
        show_end_of_buffer = false,
        term_colors = false,
        dim_inactive = {
          enabled = false,
          shade = "dark",
          percentage = 0.15,
        },
        no_italic = false,
        no_bold = false,
        no_underline = false,
        styles = {
          comments = { "italic" },
          conditionals = { "italic" },
          loops = {},
          functions = {},
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
          properties = {},
          types = {},
          operators = {},
        },
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          notify = true,
          diffview = true,
          mini = {
            enabled = true,
            indentscope_color = "",
          },
        },
      })
      -- Set catppuccin as the default colorscheme
      vim.cmd.colorscheme "catppuccin"
    end,
  },
  
  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPre", "BufNewFile" },
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

  -- Modern file icons (alternative to nvim-web-devicons)
  {
    "echasnovski/mini.icons",
    lazy = true,
    config = function()
      require("mini.icons").setup()
    end,
  },

  -- File tree explorer
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local platform_config = require('plugins.config.platform')
      local config = platform_config.get_filetree_config()
      
      require("nvim-tree").setup(config)
    end,
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

  -- Which-key for keymap hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("plugins.config.which-key").setup()
    end,
  },

  -- Notifications
  {
    "rcarriga/nvim-notify",
    lazy = false,
    priority = 900,
    config = function()
      local utils = require('core.utils')
      local notify = require("notify")
      
      -- Platform-specific configuration
      local config = {
        background_colour = utils.platform.is_mac() and "#000000" or "#1e1e1e",
        timeout = utils.platform.is_iterm2() and 3000 or 5000,
        render = utils.platform.get_capabilities().true_color and "default" or "minimal",
      }
      
      notify.setup(config)
      vim.notify = notify
    end,
  },
} 