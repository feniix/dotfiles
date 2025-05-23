-- TreeSitter configuration
-- Migrated and simplified from user/treesitter.lua

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local treesitter_configs = safe_require('nvim-treesitter.configs')
  
  if not treesitter_configs then
    return
  end

  treesitter_configs.setup({
    -- A list of parser names, or "all"
    ensure_installed = {
      "bash",
      "c",
      "cpp",
      "css",
      "dockerfile",
      "go",
      "html",
      "javascript",
      "json",
      "lua",
      "markdown",
      "python",
      "rust",
      "terraform",
      "toml",
      "typescript",
      "vim",
      "yaml",
    },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    auto_install = true,

    highlight = {
      enable = true,
      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      additional_vim_regex_highlighting = false,
    },

    indent = {
      enable = true,
    },

    -- TreeSitter textobjects
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
        },
      },
    },
  })
end

return M 