-- Indent Blankline configuration for better code structure visualization
local M = {}

function M.setup()
  local ok, ibl = pcall(require, "ibl")
  if not ok then
    -- Fallback: still show the error
    vim.notify("indent-blankline not available. Run :Lazy sync to install.", vim.log.levels.WARN)
    return {}
  end

  -- Configure indent-blankline with modern v3 API
  ibl.setup({
    -- Indentation guides
    indent = {
      char = '│',        -- Character to use for indent guides (alternatives: '▏', '┊', '┆', '¦', '|', '¦')
      tab_char = '│',    -- Character for tab indentation
      highlight = { 'IblIndent' },
      smart_indent_cap = true,
    },
    
    -- Whitespace characters
    whitespace = {
      highlight = { 'IblWhitespace' },
      remove_blankline_trail = true,
    },
    
    -- Scope highlighting (current code block)
    scope = {
      enabled = true,
      char = '│',        -- Character for current scope (alternatives: '▎', '┃')
      highlight = { 'IblScope' },
      include = {
        node_type = {
          ['*'] = {
            'class',
            'return_statement',
            'function',
            'method',
            'if_statement',
            'while_statement',
            'for_statement',
            'with_statement',
            'try_statement',
            'except_clause',
            'arguments',
            'argument_list',
            'object',
            'dictionary',
            'element',
            'table',
            'tuple',
          },
        },
      },
    },
    
    -- Exclude certain filetypes and buffer types
    exclude = {
      filetypes = {
        'help',
        'alpha',
        'dashboard',
        'neo-tree',
        'Trouble',
        'trouble',
        'lazy',
        'mason',
        'notify',
        'toggleterm',
        'lazyterm',
        'telescope',
        'TelescopePrompt',
        'TelescopeResults',
        'man',
        'lspinfo',
        'checkhealth',
        'gitcommit',
        '',                -- Empty filetype
      },
      buftypes = {
        'terminal',
        'nofile',
        'quickfix',
        'prompt',
      },
    },
  })
  
  -- Custom highlight groups for better integration with colorscheme
  local function setup_highlights()
    -- Get the current colorscheme background
    local bg = vim.api.nvim_get_option('background')
    
    if bg == 'dark' then
      -- Dark theme highlights
      vim.api.nvim_set_hl(0, 'IblIndent', { fg = '#3c3836' })      -- Subtle gray for guides
      vim.api.nvim_set_hl(0, 'IblScope', { fg = '#83a598' })       -- Blue for current scope
      vim.api.nvim_set_hl(0, 'IblWhitespace', { fg = '#3c3836' })  -- Very subtle for whitespace
    else
      -- Light theme highlights  
      vim.api.nvim_set_hl(0, 'IblIndent', { fg = '#ebdbb2' })      -- Light gray for guides
      vim.api.nvim_set_hl(0, 'IblScope', { fg = '#076678' })       -- Dark blue for current scope
      vim.api.nvim_set_hl(0, 'IblWhitespace', { fg = '#ebdbb2' })  -- Very subtle for whitespace
    end
  end
  
  -- Set up highlights now and on colorscheme change
  setup_highlights()
  
  -- Update highlights when colorscheme changes
  vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = '*',
    callback = setup_highlights,
    desc = 'Update indent-blankline highlights on colorscheme change',
  })
  
  -- Optional: Add toggle command
  vim.api.nvim_create_user_command('IndentBlanklineToggle', function()
    vim.cmd('IBLToggle')
  end, { desc = 'Toggle indent guides' })
  
  -- Optional: Add scope toggle command
  vim.api.nvim_create_user_command('IndentBlanklineScopeToggle', function()
    vim.cmd('IBLToggleScope')
  end, { desc = 'Toggle scope highlighting' })
end

return M 