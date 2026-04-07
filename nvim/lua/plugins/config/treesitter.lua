-- TreeSitter configuration for Neovim 0.12+
-- Native treesitter highlighting/indentation + nvim-treesitter for parser management

local M = {}

-- Parsers to ensure are installed
local ensure_installed = {
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
  "yaml",
}

function M.setup()
  local safe_require = _G.safe_require or require

  -- Enable native treesitter highlighting and indentation via FileType autocmd
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('TreesitterSetup', { clear = true }),
    callback = function()
      pcall(vim.treesitter.start)
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })

  -- Install missing parsers
  local ts_config = safe_require('nvim-treesitter.config')
  if ts_config then
    local installed = ts_config.get_installed()
    local to_install = vim.iter(ensure_installed)
      :filter(function(parser)
        return not vim.tbl_contains(installed, parser)
      end)
      :totable()
    if #to_install > 0 then
      require('nvim-treesitter').install(to_install)
    end
  end

  -- Setup treesitter-context (shows context at top of buffer)
  local context = safe_require('treesitter-context')
  if context then
    context.setup({
      enable = true,
      max_lines = 3,
      min_window_height = 20,
      multiline_threshold = 5,
      trim_scope = 'outer',
    })
  end
end

-- Textobjects configuration for nvim-treesitter-textobjects (main branch)
function M.setup_textobjects()
  local safe_require = _G.safe_require or require
  local ts_textobjects = safe_require('nvim-treesitter-textobjects')
  if not ts_textobjects then return end

  -- Selection
  require('nvim-treesitter-textobjects').setup({
    select = {
      lookahead = true,
      selection_modes = {
        ['@parameter.outer'] = 'v',
        ['@function.outer'] = 'V',
        ['@class.outer'] = 'V',
        ['@block.outer'] = 'V',
        ['@conditional.outer'] = 'V',
        ['@loop.outer'] = 'V',
      },
    },
  })

  -- Keymaps for textobject selection
  local select_maps = {
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
  }

  for key, query in pairs(select_maps) do
    vim.keymap.set({ 'x', 'o' }, key, function()
      require('nvim-treesitter-textobjects.select').select_textobject(query, 'textobjects')
    end, { desc = 'Select ' .. query })
  end

  -- Swap keymaps
  local swap = require('nvim-treesitter-textobjects.swap')
  vim.keymap.set('n', '<leader>sna', function() swap.swap_next('@parameter.inner') end, { desc = 'Swap next argument' })
  vim.keymap.set('n', '<leader>snm', function() swap.swap_next('@function.outer') end, { desc = 'Swap next function' })
  vim.keymap.set('n', '<leader>spa', function() swap.swap_previous('@parameter.inner') end, { desc = 'Swap previous argument' })
  vim.keymap.set('n', '<leader>spm', function() swap.swap_previous('@function.outer') end, { desc = 'Swap previous function' })

  -- Movement keymaps
  local move = require('nvim-treesitter-textobjects.move')
  local move_maps = {
    -- goto_next_start
    { ']m', function() move.goto_next_start('@function.outer') end, 'Next function start' },
    { ']]', function() move.goto_next_start('@class.outer') end, 'Next class start' },
    { ']o', function() move.goto_next_start('@loop.*') end, 'Next loop start' },
    -- goto_next_end
    { ']M', function() move.goto_next_end('@function.outer') end, 'Next function end' },
    { ']}', function() move.goto_next_end('@class.outer') end, 'Next class end' },
    { ']O', function() move.goto_next_end('@loop.*') end, 'Next loop end' },
    -- goto_previous_start
    { '[m', function() move.goto_previous_start('@function.outer') end, 'Previous function start' },
    { '[[', function() move.goto_previous_start('@class.outer') end, 'Previous class start' },
    { '[o', function() move.goto_previous_start('@loop.*') end, 'Previous loop start' },
    -- goto_previous_end
    { '[M', function() move.goto_previous_end('@function.outer') end, 'Previous function end' },
    { '[{', function() move.goto_previous_end('@class.outer') end, 'Previous class end' },
    { '[O', function() move.goto_previous_end('@loop.*') end, 'Previous loop end' },
    -- conditionals
    { ']d', function() move.goto_next_start('@conditional.outer') end, 'Next conditional' },
    { '[d', function() move.goto_previous_start('@conditional.outer') end, 'Previous conditional' },
  }

  for _, map in ipairs(move_maps) do
    vim.keymap.set({ 'n', 'x', 'o' }, map[1], map[2], { desc = map[3] })
  end
end

return M
