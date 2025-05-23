-- Python language configuration for development
-- Enhanced configuration for Python development workflow

local M = {}

function M.setup()
  -- Set up Python-specific options
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      
      -- Set buffer options following PEP 8
      vim.bo[buf].tabstop = 4
      vim.bo[buf].shiftwidth = 4
      vim.bo[buf].softtabstop = 4
      vim.bo[buf].expandtab = true
      vim.bo[buf].textwidth = 88  -- Black formatter default
      vim.wo.colorcolumn = "88"  -- Window-local option, not buffer-local
      
      -- Set local keymaps
      M.setup_python_keymaps(buf)
    end,
    desc = "Python buffer configuration",
  })

  -- Set up autocommands for Python files
  M.setup_autocmds()
  
  -- Set up custom commands
  M.setup_commands()
end

function M.setup_python_keymaps(buf)
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true, buffer = buf }
  
  -- Python formatting and linting
  keymap('n', '<leader>pf', ':PythonFormat<CR>', vim.tbl_extend('force', opts, { desc = 'Format Python (Black)' }))
  keymap('n', '<leader>pi', ':PythonImports<CR>', vim.tbl_extend('force', opts, { desc = 'Sort imports (isort)' }))
  keymap('n', '<leader>pl', ':PythonLint<CR>', vim.tbl_extend('force', opts, { desc = 'Python lint (flake8)' }))
  keymap('n', '<leader>pt', ':PythonType<CR>', vim.tbl_extend('force', opts, { desc = 'Type check (mypy)' }))
  
  -- Python testing
  keymap('n', '<leader>pr', ':PythonRun<CR>', vim.tbl_extend('force', opts, { desc = 'Run Python file' }))
  keymap('n', '<leader>pT', ':PythonTest<CR>', vim.tbl_extend('force', opts, { desc = 'Run tests (pytest)' }))
  keymap('n', '<leader>pc', ':PythonCoverage<CR>', vim.tbl_extend('force', opts, { desc = 'Coverage report' }))
  
  -- Python REPL and debugging
  keymap('n', '<leader>pR', ':PythonREPL<CR>', vim.tbl_extend('force', opts, { desc = 'Open Python REPL' }))
  keymap('n', '<leader>pd', ':PythonDebug<CR>', vim.tbl_extend('force', opts, { desc = 'Debug with pdb' }))
  
  -- Documentation and help
  keymap('n', '<leader>ph', ':PythonDoc<CR>', vim.tbl_extend('force', opts, { desc = 'Python docs' }))
  keymap('n', '<leader>pv', ':PythonVersion<CR>', vim.tbl_extend('force', opts, { desc = 'Python version' }))
end

function M.setup_autocmds()
  local augroup = vim.api.nvim_create_augroup("PythonConfig", { clear = true })
  
  -- Auto-format on save (optional)
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    pattern = "*.py",
    callback = function()
      if vim.g.python_format_on_save then
        M.format_python()
      end
    end,
    desc = "Auto-format Python files on save",
  })
  
  -- Set comment string for Python files
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "python",
    callback = function()
      vim.bo.commentstring = "# %s"
    end,
    desc = "Set comment string for Python files",
  })
  
  -- Python-specific folding
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "python",
    callback = function()
      vim.wo.foldmethod = "indent"
      vim.wo.foldlevel = 99  -- Start with all folds open
    end,
    desc = "Set Python-specific folding",
  })
end

function M.setup_commands()
  -- Python formatting and linting commands
  vim.api.nvim_create_user_command('PythonFormat', function()
    M.format_python()
  end, { desc = 'Format Python file with Black' })
  
  vim.api.nvim_create_user_command('PythonImports', function()
    M.sort_imports()
  end, { desc = 'Sort Python imports with isort' })
  
  vim.api.nvim_create_user_command('PythonLint', function()
    M.lint_python()
  end, { desc = 'Lint Python file with flake8' })
  
  vim.api.nvim_create_user_command('PythonType', function()
    M.type_check()
  end, { desc = 'Type check Python file with mypy' })
  
  -- Python execution commands
  vim.api.nvim_create_user_command('PythonRun', function()
    M.run_python()
  end, { desc = 'Run Python file' })
  
  vim.api.nvim_create_user_command('PythonTest', function()
    M.run_tests()
  end, { desc = 'Run Python tests with pytest' })
  
  vim.api.nvim_create_user_command('PythonCoverage', function()
    M.run_coverage()
  end, { desc = 'Run coverage report' })
  
  -- Python REPL and debugging
  vim.api.nvim_create_user_command('PythonREPL', function()
    M.open_repl()
  end, { desc = 'Open Python REPL' })
  
  vim.api.nvim_create_user_command('PythonDebug', function()
    M.debug_python()
  end, { desc = 'Debug Python file with pdb' })
  
  -- Python utilities
  vim.api.nvim_create_user_command('PythonDoc', function()
    M.open_python_docs()
  end, { desc = 'Open Python documentation' })
  
  vim.api.nvim_create_user_command('PythonVersion', function()
    M.show_python_version()
  end, { desc = 'Show Python version' })
end

-- Format Python file with Black
function M.format_python()
  local file = vim.fn.expand('%')
  if vim.fn.executable('black') == 1 then
    local result = vim.fn.system('black --stdin-filename ' .. vim.fn.shellescape(file) .. ' -', vim.api.nvim_buf_get_lines(0, 0, -1, false))
    if vim.v.shell_error == 0 then
      local lines = vim.split(result, '\n')
      if lines[#lines] == '' then
        table.remove(lines)  -- Remove trailing empty line
      end
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.notify("Python file formatted with Black", vim.log.levels.INFO)
    else
      vim.notify("Black formatting failed: " .. result, vim.log.levels.ERROR)
    end
  else
    vim.notify("black not found. Install with: pip install black", vim.log.levels.ERROR)
  end
end

-- Sort imports with isort
function M.sort_imports()
  local file = vim.fn.expand('%')
  if vim.fn.executable('isort') == 1 then
    local result = vim.fn.system('isort --stdout ' .. vim.fn.shellescape(file))
    if vim.v.shell_error == 0 then
      local lines = vim.split(result, '\n')
      if lines[#lines] == '' then
        table.remove(lines)  -- Remove trailing empty line
      end
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.notify("Imports sorted with isort", vim.log.levels.INFO)
    else
      vim.notify("isort failed: " .. result, vim.log.levels.ERROR)
    end
  else
    vim.notify("isort not found. Install with: pip install isort", vim.log.levels.ERROR)
  end
end

-- Lint Python file with flake8
function M.lint_python()
  local file = vim.fn.expand('%')
  if vim.fn.executable('flake8') == 1 then
    local result = vim.fn.system('flake8 ' .. vim.fn.shellescape(file))
    if vim.v.shell_error == 0 then
      vim.notify("flake8 found no issues", vim.log.levels.INFO)
    else
      -- Parse flake8 output and populate quickfix
      local lines = vim.split(result, '\n')
      local qf_list = {}
      for _, line in ipairs(lines) do
        if line ~= '' then
          local filename, lnum, col, msg = line:match('([^:]+):(%d+):(%d+): (.+)')
          if filename and lnum and col and msg then
            table.insert(qf_list, {
              filename = filename,
              lnum = tonumber(lnum),
              col = tonumber(col),
              text = msg,
              type = 'E'
            })
          end
        end
      end
      vim.fn.setqflist(qf_list)
      vim.cmd('copen')
      vim.notify("flake8 found issues (see quickfix)", vim.log.levels.WARN)
    end
  else
    vim.notify("flake8 not found. Install with: pip install flake8", vim.log.levels.ERROR)
  end
end

-- Type check with mypy
function M.type_check()
  local file = vim.fn.expand('%')
  if vim.fn.executable('mypy') == 1 then
    local result = vim.fn.system('mypy ' .. vim.fn.shellescape(file))
    if vim.v.shell_error == 0 then
      vim.notify("mypy found no type issues", vim.log.levels.INFO)
    else
      vim.notify("mypy type check failed:\n" .. result, vim.log.levels.WARN)
    end
  else
    vim.notify("mypy not found. Install with: pip install mypy", vim.log.levels.ERROR)
  end
end

-- Run Python file
function M.run_python()
  local file = vim.fn.expand('%')
  local python_cmd = vim.fn.executable('python3') == 1 and 'python3' or 'python'
  
  if vim.fn.executable(python_cmd) == 1 then
    local cmd = python_cmd .. ' ' .. vim.fn.shellescape(file)
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  else
    vim.notify("Python not found", vim.log.levels.ERROR)
  end
end

-- Run tests with pytest
function M.run_tests()
  if vim.fn.executable('pytest') == 1 then
    local cmd = 'pytest -v'
    
    -- Check if we're in a test file
    local file = vim.fn.expand('%')
    if file:match('test_.*%.py$') or file:match('.*_test%.py$') then
      cmd = cmd .. ' ' .. vim.fn.shellescape(file)
    end
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  else
    vim.notify("pytest not found. Install with: pip install pytest", vim.log.levels.ERROR)
  end
end

-- Run coverage report
function M.run_coverage()
  if vim.fn.executable('coverage') == 1 then
    local cmd = 'coverage run -m pytest && coverage report'
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  else
    vim.notify("coverage not found. Install with: pip install coverage", vim.log.levels.ERROR)
  end
end

-- Open Python REPL
function M.open_repl()
  local python_cmd = vim.fn.executable('python3') == 1 and 'python3' or 'python'
  
  if vim.fn.executable(python_cmd) == 1 then
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. python_cmd)
    vim.cmd('startinsert')
  else
    vim.notify("Python not found", vim.log.levels.ERROR)
  end
end

-- Debug Python file with pdb
function M.debug_python()
  local file = vim.fn.expand('%')
  local python_cmd = vim.fn.executable('python3') == 1 and 'python3' or 'python'
  
  if vim.fn.executable(python_cmd) == 1 then
    local cmd = python_cmd .. ' -m pdb ' .. vim.fn.shellescape(file)
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  else
    vim.notify("Python not found", vim.log.levels.ERROR)
  end
end

-- Open Python documentation
function M.open_python_docs()
  local url = "https://docs.python.org/3/"
  if vim.fn.has('mac') == 1 then
    vim.fn.system('open ' .. url)
  elseif vim.fn.has('unix') == 1 then
    vim.fn.system('xdg-open ' .. url)
  else
    vim.notify("Open " .. url .. " in your browser", vim.log.levels.INFO)
  end
end

-- Show Python version
function M.show_python_version()
  local python_cmd = vim.fn.executable('python3') == 1 and 'python3' or 'python'
  
  if vim.fn.executable(python_cmd) == 1 then
    local result = vim.fn.system(python_cmd .. ' --version')
    vim.notify("Python version: " .. result:gsub('\n', ''), vim.log.levels.INFO)
  else
    vim.notify("Python not found", vim.log.levels.ERROR)
  end
end

return M 