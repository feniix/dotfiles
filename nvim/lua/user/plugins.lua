-- Lazy.nvim plugin management
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

return require("lazy").setup({
  -- ---- Core ----
  {
    "editorconfig/editorconfig-vim",
    event = "VeryLazy",
  },

  -- ---- UI ----
  -- NeoSolarized theme
  {
    "svrana/neosolarized.nvim",
    dependencies = { "tjdevries/colorbuddy.nvim" },
    lazy = false,
    priority = 1000,
  },
  
  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    config = function()
      if safe_require('user.indent-blankline') then
        require('user.indent-blankline').setup()
      end
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
  },

  -- ---- Language Support ----
  -- Terraform
  {
    "hashivim/vim-terraform",
    ft = { "terraform", "hcl" },
  },

  -- Puppet
  {
    "rodjek/vim-puppet",
    ft = "puppet",
  },

  -- Go
  {
    "fatih/vim-go",
    ft = "go",
    build = ":GoUpdateBinaries",
  },
  
  {
    "AndrewRadev/splitjoin.vim",
    keys = { "gS", "gJ" },
  },

  -- ---- Neovim Specific ----
  -- Debugging (lazy loaded)
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
          -- DAP UI setup moved to after/ plugin
        end,
      },
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      if safe_require('user.dap') then
        require('user.dap').setup()
      end
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      if safe_require('user.treesitter') then
        require('user.treesitter').setup()
      end
    end,
  },

  -- TreeSitter context-aware commenting
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
  },

  -- Modern completion system
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path", 
      "hrsh7th/cmp-cmdline",
    },
  },

  -- Telescope - Fuzzy finder over lists
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
      if safe_require('user.telescope') then
        require('user.telescope').setup()
      end
    end,
  },

  -- ---- Modern replacements ----
  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
  },

  -- Surround text objects
  {
    "kylechui/nvim-surround",
    event = { "BufReadPost", "BufNewFile" },
  },

  -- Whitespace management
  {
    "kaplanz/retrail.nvim",
    event = { "BufReadPost", "BufNewFile" },
  },

  -- Rainbow parentheses
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
  },

  -- ---- Extra niceties ----
  -- TODO comments
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Commenting plugin
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n", desc = "Comment toggle current line" },
      { "gc", mode = { "n", "o" }, desc = "Comment toggle linewise" },
      { "gc", mode = "x", desc = "Comment toggle linewise (visual)" },
      { "gbc", mode = "n", desc = "Comment toggle current block" },
      { "gb", mode = { "n", "o" }, desc = "Comment toggle blockwise" },
      { "gb", mode = "x", desc = "Comment toggle blockwise (visual)" },
    },
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
  },

  -- Which Key - Keymap discovery and organization
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      if safe_require('user.which-key') then
        require('user.which-key').setup()
      end
    end,
  },

  -- Git diff viewer
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    config = function()
      if safe_require('user.diffview') then
        require('user.diffview').setup()
      end
    end,
  },
}, {
  -- lazy.nvim options
  ui = {
    border = "rounded",
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen", 
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
}) 