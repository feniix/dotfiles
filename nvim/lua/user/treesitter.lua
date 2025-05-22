local M = {}

M.setup = function()
  -- Safely require treesitter
  local treesitter_ok, treesitter = pcall(require, 'nvim-treesitter.configs')
  if not treesitter_ok then
    vim.notify("nvim-treesitter not found. Syntax highlighting may be limited.", vim.log.levels.WARN)
    return
  end

  -- Setup treesitter for better syntax highlighting and code navigation
  treesitter.setup {
    -- Install parsers for these languages automatically
    ensure_installed = {
      "bash",
      "c",
      "cpp",
      "css",
      "dockerfile",
      "go",
      "graphql",
      "html",
      "javascript",
      "json",
      "jsonnet",
      "lua",
      "markdown",
      "python",
      "regex",
      "ruby",
      "rust",
      "terraform",
      "toml",
      "tsx",
      "typescript",
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
          -- You can use the capture groups defined in textobjects.scm
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["ab"] = "@block.outer",
          ["ib"] = "@block.inner",
        },
        -- You can choose the select mode (default is charwise 'v')
        selection_modes = {
          ['@parameter.outer'] = 'v', -- charwise
          ['@function.outer'] = 'V', -- linewise
          ['@class.outer'] = '<c-v>', -- blockwise
        },
      },
      
      -- Allow swapping text objects
      swap = {
        enable = true,
        swap_next = {
          ["<leader>a"] = "@parameter.inner",
        },
        swap_previous = {
          ["<leader>A"] = "@parameter.inner",
        },
      },
      
      -- Allow moving between text objects
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
          ["]["] = "@class.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
          ["[]"] = "@class.outer",
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
  local context_ok, context = pcall(require, 'treesitter-context')
  if context_ok then
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
        typescript = {
          'class_declaration',
          'function_declaration',
          'method_declaration',
          'arrow_function',
          'function',
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
      local ts_parsers = require('nvim-treesitter.parsers')
      local ts_install = require('nvim-treesitter.install')
      local parser_config = ts_parsers.get_parser_configs()
      
      if parser_config[lang] then
        ts_install.commands.TSInstall.run(lang)
      else
        vim.notify("Parser not found for language: " .. lang, vim.log.levels.ERROR)
      end
    end
  end, { nargs = 1, desc = "Install TreeSitter parser from git" })
  
  -- Try to manually install the vim parser if it's not already installed
  local setup_ts = safe_require('user.setup_treesitter')
  if setup_ts then
    vim.defer_fn(function()
      setup_ts.install_vim_parser()
    end, 1000)  -- Defer by 1 second to let Neovim finish startup
  end
end

return M 