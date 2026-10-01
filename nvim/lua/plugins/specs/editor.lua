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
    -- 0.1.8 calls nvim-treesitter's removed ft_to_lang in previews; master
    -- uses vim.treesitter.language.get_lang.
    branch = "master",
    cmd = "Telescope",
    -- Declared here, not in config(), so the mappings exist before the
    -- plugin loads; the first press loads telescope.
    keys = function()
      local function pick(name)
        return function()
          local telescope = require("plugins.config.telescope")
          local builtin = require("telescope.builtin")
          telescope.safe_telescope_call(builtin[name])
        end
      end
      local function key(lhs, name, desc)
        return { lhs, pick(name), desc = desc, silent = true }
      end
      return {
        -- File pickers
        key("<leader>ff", "find_files", "Telescope find files"),
        key("<leader>fg", "live_grep", "Telescope live grep"),
        key("<leader>fb", "buffers", "Telescope buffers"),
        key("<leader>fh", "help_tags", "Telescope help tags"),
        key("<leader>fr", "oldfiles", "Telescope recent files"),
        key("<leader>fc", "colorscheme", "Telescope colorschemes"),
        -- Search
        key("<leader>fw", "grep_string", "Telescope grep string under cursor"),
        {
          "<leader>fs",
          function()
            local telescope = require("plugins.config.telescope")
            if not telescope.can_open_telescope() then return end
            telescope.safe_telescope_call(require("telescope.builtin").grep_string,
              { search = vim.fn.input("Grep > ") })
          end,
          desc = "Telescope grep search",
          silent = true,
        },
        -- Git
        key("<leader>gc", "git_commits", "Telescope git commits"),
        key("<leader>gb", "git_branches", "Telescope git branches"),
        key("<leader>gs", "git_status", "Telescope git status"),
        -- LSP
        key("<leader>lr", "lsp_references", "Telescope LSP references"),
        key("<leader>ld", "lsp_definitions", "Telescope LSP definitions"),
        key("<leader>li", "lsp_implementations", "Telescope LSP implementations"),
        key("<leader>ls", "lsp_document_symbols", "Telescope LSP document symbols"),
        key("<leader>lw", "lsp_workspace_symbols", "Telescope LSP workspace symbols"),
        -- Vim
        key("<leader>fk", "keymaps", "Telescope keymaps"),
        key("<leader>fm", "marks", "Telescope marks"),
        key("<leader>fo", "vim_options", "Telescope vim options"),
        key("<leader>ft", "filetypes", "Telescope filetypes"),
        -- Convenience
        key("<C-p>", "find_files", "Telescope find files"),
        key("<C-f>", "live_grep", "Telescope live grep"),
      }
    end,
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

  -- TreeSitter for syntax highlighting (Neovim 0.12+ native treesitter)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("plugins.config.treesitter").setup()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("plugins.config.treesitter").setup_textobjects()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- Context setup is handled in treesitter config
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
