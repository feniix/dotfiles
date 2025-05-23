-- TreeSitter configuration for advanced syntax highlighting and code navigation
-- Migrated and enhanced from user/treesitter.lua

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local treesitter = safe_require('nvim-treesitter.configs')
  
  if not treesitter then
    vim.notify("nvim-treesitter not found. Syntax highlighting may be limited.", vim.log.levels.WARN)
    return
  end

  -- Setup treesitter for better syntax highlighting and code navigation
  treesitter.setup {
    -- Install parsers for these languages automatically
    ensure_installed = {
      "bash",
      "c",
      "comment",
      "cpp",
      "css",
      "dockerfile",
      "go",
      "gomod",
      "gosum",
      "gotmpl",
      "gowork",
      "graphql",
      "html",
      "json",
      "jsonnet",
      "lua",
      "markdown",
      "python",
      "regex",
      "ruby",
      "rust",
      "sql",
      "terraform",
      "toml",
      -- Temporarily removing vim from auto-install if causing issues
      -- "vim",
      "yaml",
    },
    
    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,
    
    -- Automatically install missing parsers when entering buffer
    auto_install = true,
    
    -- List of parsers to ignore installing
    ignore_install = { "vim" },  -- Ignore vim parser if it's causing issues
    
    -- Download protocol (default: "https")
    -- If you're having issues with https, try using "git"
    download_protocol = "git",
    
    -- Indentation based on treesitter for the = operator
    indent = {
      enable = true
    },
    
    -- Syntax highlighting configuration
    highlight = {
      -- `false` will disable the whole extension
      enable = true,
      
      -- List of languages that will be disabled
      disable = {},
      
      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      additional_vim_regex_highlighting = false,
    },
    
    -- Text objects selection
    textobjects = {
      select = {
        enable = true,
        
        -- Automatically jump forward to textobj, similar to targets.vim
        lookahead = true,
        
        keymaps = {
          -- Functions
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          
          -- Classes
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          
          -- Blocks
          ["ab"] = "@block.outer",
          ["ib"] = "@block.inner",
          
          -- Parameters/Arguments
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
          
          -- Conditionals
          ["ai"] = "@conditional.outer",
          ["ii"] = "@conditional.inner",
          
          -- Loops
          ["al"] = "@loop.outer",
          ["il"] = "@loop.inner",
          
          -- Calls
          ["aC"] = "@call.outer",
          ["iC"] = "@call.inner",
          
          -- Comments
          ["aM"] = "@comment.outer",
          ["iM"] = "@comment.inner",
          
          -- Assignments
          ["a="] = "@assignment.outer",
          ["i="] = "@assignment.inner",
          
          -- Numbers
          ["aN"] = "@number.inner",
          ["iN"] = "@number.inner",
          
          -- Returns
          ["aR"] = "@return.outer",
          ["iR"] = "@return.inner",
        },
        
        -- You can choose the select mode (default is charwise 'v')
        selection_modes = {
          ['@parameter.outer'] = 'v', -- charwise
          ['@function.outer'] = 'V', -- linewise
          ['@class.outer'] = 'V', -- linewise
          ['@block.outer'] = 'V', -- linewise
          ['@conditional.outer'] = 'V', -- linewise
          ['@loop.outer'] = 'V', -- linewise
        },
        
        -- If you set this to `true` (default is `false`) then any textobject is
        -- extended to include preceding xor succeeding whitespace.
        include_surrounding_whitespace = false,
      },
      
      -- Allow swapping text objects
      swap = {
        enable = true,
        swap_next = {
          ["<leader>sna"] = "@parameter.inner", -- swap next argument
          ["<leader>snm"] = "@function.outer", -- swap next method/function
        },
        swap_previous = {
          ["<leader>spa"] = "@parameter.inner", -- swap previous argument
          ["<leader>spm"] = "@function.outer", -- swap previous method/function
        },
      },
      
      -- Allow moving between text objects
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
          ["]o"] = "@loop.*",
          ["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
          ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
          ["]}"] = "@class.outer",
          ["]O"] = "@loop.*",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
          ["[o"] = "@loop.*",
          ["[s"] = { query = "@scope", query_group = "locals", desc = "Previous scope" },
          ["[z"] = { query = "@fold", query_group = "folds", desc = "Previous fold" },
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
          ["[{"] = "@class.outer",
          ["[O"] = "@loop.*",
        },
        -- Below will go to either the start or the end, whichever is closer.
        -- Use if you want more granular movements
        -- Make it even more gradual by adding multiple queries and regex.
        goto_next = {
          ["]d"] = "@conditional.outer",
        },
        goto_previous = {
          ["[d"] = "@conditional.outer",
        }
      },
      
      -- LSP interop for better integration
      lsp_interop = {
        enable = true,
        border = 'rounded',
        floating_preview_opts = {},
        peek_definition_code = {
          ["<leader>df"] = "@function.outer",
          ["<leader>dF"] = "@class.outer",
        },
      },
    },
    
    -- Playground for development debugging
    playground = {
      enable = true,
      disable = {},
      updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
      persist_queries = false, -- Whether the query persists across vim sessions
    },
    
    -- Autotag extension configuration (auto close/rename HTML tags)
    autotag = {
      enable = true,
    },
  }
  
  -- Setup treesitter-context (shows context at top of buffer)
  local context = safe_require('treesitter-context')
  if context then
    context.setup({
      enable = true,
      max_lines = 3, -- How many lines the context will try to show
      min_window_height = 20, -- Only show context if window has enough height
      multiline_threshold = 5, -- Maximum number of lines for a multi-line node
      trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded 
      patterns = { -- Which nodes to show in context
        default = {
          'class',
          'function',
          'method',
          'for',
          'while',
          'if',
          'switch',
          'case',
          'interface',
          'struct',
          'enum',
        },
        -- Add language-specific patterns here if needed
        go = {
          'func_literal',
          'function_declaration',
          'method_declaration',
          'struct_type',
          'interface_type',
        },
      },
    })
  end
  
  -- Create custom command to manually install parsers
  vim.api.nvim_create_user_command("TSInstallFromGit", function(opts)
    local lang = opts.args
    if not lang or lang == "" then
      vim.notify("Please specify a language", vim.log.levels.ERROR)
      return
    end
    
    local install_cmd = string.format("TSInstall %s", lang)
    local ok, err = pcall(vim.cmd, install_cmd)
    if not ok then
      vim.notify("Failed to install " .. lang .. " parser: " .. err, vim.log.levels.ERROR)
      
      -- Try installing from git as fallback
      vim.notify("Trying to install " .. lang .. " parser from git...", vim.log.levels.INFO)
      local ts_parsers = safe_require('nvim-treesitter.parsers')
      local ts_install = safe_require('nvim-treesitter.install')
      
      if ts_parsers and ts_install then
        local parser_config = ts_parsers.get_parser_configs()
        
        if parser_config[lang] then
          ts_install.commands.TSInstall.run(lang)
        else
          vim.notify("Parser not found for language: " .. lang, vim.log.levels.ERROR)
        end
      end
    end
  end, { nargs = 1, desc = "Install TreeSitter parser from git" })
  
  -- Note: Setup utilities are now integrated into this configuration
  -- The old user.setup_treesitter functionality has been migrated here
  
  -- Apply any user overrides if available
end

return M 