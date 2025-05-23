-- Go development configuration
-- Migrated from user/go.lua

local M = {}

-- Helper function to jump between Go files (test/implementation)
local function open_alternate(command)
  local file = vim.fn.expand("%")
  if file == "" then
    vim.notify("No file in the current buffer", vim.log.levels.ERROR)
    return
  end
  
  -- Determine if this is a test file
  local is_test = vim.fn.match(file, "_test\\.go$") ~= -1
  local alternate
  
  if is_test then
    -- If it's a test file, get the implementation file
    alternate = file:gsub("_test%.go$", ".go")
  else
    -- If it's an implementation file, get the test file
    alternate = file:gsub("%.go$", "_test.go")
  end
  
  -- Check if the alternate file exists
  if vim.fn.filereadable(alternate) == 0 then
    vim.notify("Alternate file doesn't exist: " .. alternate, vim.log.levels.WARN)
  end
  
  -- Open the alternate file with the specified command
  vim.cmd(command .. " " .. alternate)
end

-- Functions to open alternate file in different ways
function M.go_alternate_edit()
  open_alternate("e")
end

function M.go_alternate_split()
  open_alternate("sp")
end

function M.go_alternate_vertical()
  open_alternate("vsp")
end

function M.go_alternate_tab()
  open_alternate("tabe")
end

-- Build Go files (implementation of the reference in init.lua)
function M.build_go_files()
  local file = vim.fn.expand('%')
  if file:match('_test%.go$') then
    vim.cmd('GoTest')
  elseif file:match('%.go$') then
    vim.cmd('GoBuild')
  end
end

-- Set up Go-specific key mappings (buffer-local)
function M.setup_keymaps()
  -- Only set up keymaps for Go files
  if vim.bo.filetype ~= 'go' then
    return
  end
  
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true, buffer = true }
  
  -- Go-specific leader mappings (buffer-local)
  keymap('n', '<leader>Gb', M.build_go_files, vim.tbl_extend('force', opts, { desc = 'Build Go files' }))
  keymap('n', '<leader>Gt', ':GoTest<CR>', vim.tbl_extend('force', opts, { desc = 'Go test' }))
  keymap('n', '<leader>Gr', ':GoRun<CR>', vim.tbl_extend('force', opts, { desc = 'Go run' }))
  keymap('n', '<leader>Gd', ':GoDoc<CR>', vim.tbl_extend('force', opts, { desc = 'Go doc' }))
  keymap('n', '<leader>Gc', ':GoCoverageToggle<CR>', vim.tbl_extend('force', opts, { desc = 'Go coverage toggle' }))
  keymap('n', '<leader>Gi', ':GoInfo<CR>', vim.tbl_extend('force', opts, { desc = 'Go info' }))
  keymap('n', '<leader>Gv', M.go_alternate_vertical, vim.tbl_extend('force', opts, { desc = 'Go def vertical split' }))
  keymap('n', '<leader>Gs', M.go_alternate_split, vim.tbl_extend('force', opts, { desc = 'Go def horizontal split' }))
  keymap('n', '<leader>Gl', ':GoMetaLinter<CR>', vim.tbl_extend('force', opts, { desc = 'Go metalinter' }))
  
  -- Alternate file mappings
  keymap('n', '<leader>A', M.go_alternate_edit, vim.tbl_extend('force', opts, { desc = 'Alternate Go file' }))
end

-- Module setup function
function M.setup()
  vim.notify("Using vim-go for Go development (LSP disabled)", vim.log.levels.INFO)
  
  -- Set up autocommand to set keymaps when Go files are opened
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'go',
    callback = function()
      M.setup_keymaps()
      
      -- Set up which-key mappings for Go files if available
      local safe_require = _G.safe_require or require
      local which_key = safe_require('plugins.config.which-key')
      if which_key and which_key.setup_go_mappings then
        which_key.setup_go_mappings()
      end
    end,
    desc = 'Set up Go-specific keymaps',
  })
end

return M
