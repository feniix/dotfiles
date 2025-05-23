-- Puppet language configuration for configuration management
-- Enhanced configuration for Puppet development and linting

local M = {}

function M.setup()
  -- Set up Puppet-specific options
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "puppet",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      
      -- Set buffer options following Puppet style guide
      vim.bo[buf].tabstop = 2
      vim.bo[buf].shiftwidth = 2
      vim.bo[buf].softtabstop = 2
      vim.bo[buf].expandtab = true
      vim.bo[buf].textwidth = 140  -- Modern Puppet line length
      
      -- Set local keymaps
      M.setup_puppet_keymaps(buf)
    end,
    desc = "Puppet buffer configuration",
  })

  -- Set up autocommands for Puppet files
  M.setup_autocmds()
  
  -- Set up custom commands
  M.setup_commands()
end

function M.setup_puppet_keymaps(buf)
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true, buffer = buf }
  
  -- Puppet linting and validation
  keymap('n', '<leader>pl', ':PuppetLint<CR>', vim.tbl_extend('force', opts, { desc = 'Puppet lint' }))
  keymap('n', '<leader>pf', ':PuppetLintFix<CR>', vim.tbl_extend('force', opts, { desc = 'Puppet lint --fix' }))
  keymap('n', '<leader>pv', ':PuppetValidate<CR>', vim.tbl_extend('force', opts, { desc = 'Puppet validate' }))
  keymap('n', '<leader>ps', ':PuppetSyntax<CR>', vim.tbl_extend('force', opts, { desc = 'Puppet syntax check' }))
  
  -- Puppet documentation and help
  keymap('n', '<leader>ph', ':PuppetDoc<CR>', vim.tbl_extend('force', opts, { desc = 'Puppet docs' }))
  keymap('n', '<leader>pm', ':PuppetModulePath<CR>', vim.tbl_extend('force', opts, { desc = 'Show module path' }))
  
  -- Puppet development helpers
  keymap('n', '<leader>pa', ':PuppetApply<CR>', vim.tbl_extend('force', opts, { desc = 'Puppet apply (dry-run)' }))
  keymap('n', '<leader>pc', ':PuppetCompile<CR>', vim.tbl_extend('force', opts, { desc = 'Puppet compile' }))
end

function M.setup_autocmds()
  local augroup = vim.api.nvim_create_augroup("PuppetConfig", { clear = true })
  
  -- Auto-lint on save (optional)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    pattern = "*.pp",
    callback = function()
      if vim.g.puppet_lint_on_save then
        vim.cmd("PuppetLint")
      end
    end,
    desc = "Auto-lint Puppet files on save",
  })
  
  -- Set comment string for Puppet files
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "puppet",
    callback = function()
      vim.bo.commentstring = "# %s"
    end,
    desc = "Set comment string for Puppet files",
  })
  
  -- Highlight Puppet keywords and types
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "puppet",
    callback = function()
      -- Additional syntax highlighting for Puppet-specific keywords
      vim.cmd([[
        syntax keyword puppetKeyword ensure notify subscribe require before
        syntax keyword puppetKeyword present absent installed latest running stopped
        highlight link puppetKeyword Keyword
      ]])
    end,
    desc = "Enhanced Puppet syntax highlighting",
  })
end

function M.setup_commands()
  -- Puppet linting commands
  vim.api.nvim_create_user_command('PuppetLint', function()
    M.run_puppet_lint()
  end, { desc = 'Run puppet-lint on current file' })
  
  vim.api.nvim_create_user_command('PuppetLintFix', function()
    M.run_puppet_lint(true)
  end, { desc = 'Run puppet-lint --fix on current file' })
  
  -- Puppet validation commands
  vim.api.nvim_create_user_command('PuppetValidate', function()
    M.validate_puppet()
  end, { desc = 'Validate Puppet syntax' })
  
  vim.api.nvim_create_user_command('PuppetSyntax', function()
    M.check_puppet_syntax()
  end, { desc = 'Check Puppet syntax' })
  
  -- Puppet apply commands
  vim.api.nvim_create_user_command('PuppetApply', function()
    M.puppet_apply()
  end, { desc = 'Run puppet apply --noop on current file' })
  
  vim.api.nvim_create_user_command('PuppetCompile', function()
    M.puppet_compile()
  end, { desc = 'Compile Puppet catalog' })
  
  -- Puppet documentation
  vim.api.nvim_create_user_command('PuppetDoc', function()
    M.open_puppet_docs()
  end, { desc = 'Open Puppet documentation' })
  
  vim.api.nvim_create_user_command('PuppetModulePath', function()
    M.show_module_path()
  end, { desc = 'Show Puppet module path' })
end

-- Run puppet-lint on current file
function M.run_puppet_lint(fix)
  local file = vim.fn.expand('%')
  if not file:match('%.pp$') then
    vim.notify("Not a Puppet file", vim.log.levels.WARN)
    return
  end
  
  if vim.fn.executable('puppet-lint') == 1 then
    local cmd = 'puppet-lint'
    if fix then
      cmd = cmd .. ' --fix'
    end
    cmd = cmd .. ' ' .. vim.fn.shellescape(file)
    
    local result = vim.fn.system(cmd)
    if vim.v.shell_error == 0 then
      if fix then
        -- Reload the file to show fixes
        vim.cmd('edit!')
        vim.notify("Puppet file fixed and reloaded", vim.log.levels.INFO)
      else
        vim.notify("Puppet lint passed", vim.log.levels.INFO)
      end
    else
      -- Show lint errors in quickfix
      local lines = vim.split(result, '\n')
      local qf_list = {}
      for _, line in ipairs(lines) do
        if line ~= '' then
          local filename, lnum, msg = line:match('([^:]+):(%d+):(.+)')
          if filename and lnum and msg then
            table.insert(qf_list, {
              filename = filename,
              lnum = tonumber(lnum),
              text = msg:gsub('^%s+', ''),  -- trim whitespace
              type = 'E'
            })
          end
        end
      end
      vim.fn.setqflist(qf_list)
      vim.cmd('copen')
      vim.notify("Puppet lint found issues (see quickfix)", vim.log.levels.WARN)
    end
  else
    vim.notify("puppet-lint not found. Install with: gem install puppet-lint", vim.log.levels.ERROR)
  end
end

-- Validate Puppet syntax
function M.validate_puppet()
  local file = vim.fn.expand('%')
  if vim.fn.executable('puppet') == 1 then
    local cmd = 'puppet parser validate ' .. vim.fn.shellescape(file)
    local result = vim.fn.system(cmd)
    if vim.v.shell_error == 0 then
      vim.notify("Puppet syntax is valid", vim.log.levels.INFO)
    else
      vim.notify("Puppet syntax error: " .. result, vim.log.levels.ERROR)
    end
  else
    vim.notify("puppet command not found", vim.log.levels.ERROR)
  end
end

-- Check Puppet syntax (alternative method)
function M.check_puppet_syntax()
  local file = vim.fn.expand('%')
  if vim.fn.executable('puppet') == 1 then
    local cmd = 'puppet apply --parseonly --noop ' .. vim.fn.shellescape(file)
    local result = vim.fn.system(cmd)
    if vim.v.shell_error == 0 then
      vim.notify("Puppet syntax check passed", vim.log.levels.INFO)
    else
      vim.notify("Puppet syntax error: " .. result, vim.log.levels.ERROR)
    end
  else
    vim.notify("puppet command not found", vim.log.levels.ERROR)
  end
end

-- Apply Puppet manifest (dry-run)
function M.puppet_apply()
  local file = vim.fn.expand('%')
  if vim.fn.executable('puppet') == 1 then
    local cmd = string.format('puppet apply --noop --verbose %s', vim.fn.shellescape(file))
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  else
    vim.notify("puppet command not found", vim.log.levels.ERROR)
  end
end

-- Compile Puppet catalog
function M.puppet_compile()
  if vim.fn.executable('puppet') == 1 then
    local cmd = 'puppet catalog compile $(hostname -f)'
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  else
    vim.notify("puppet command not found", vim.log.levels.ERROR)
  end
end

-- Open Puppet documentation
function M.open_puppet_docs()
  local url = "https://puppet.com/docs/puppet/latest/lang_visual_index.html"
  if vim.fn.has('mac') == 1 then
    vim.fn.system('open ' .. url)
  elseif vim.fn.has('unix') == 1 then
    vim.fn.system('xdg-open ' .. url)
  else
    vim.notify("Open " .. url .. " in your browser", vim.log.levels.INFO)
  end
end

-- Show Puppet module path
function M.show_module_path()
  if vim.fn.executable('puppet') == 1 then
    local result = vim.fn.system('puppet config print modulepath')
    if vim.v.shell_error == 0 then
      vim.notify("Module path: " .. result, vim.log.levels.INFO)
    else
      vim.notify("Failed to get module path", vim.log.levels.ERROR)
    end
  else
    vim.notify("puppet command not found", vim.log.levels.ERROR)
  end
end

return M 