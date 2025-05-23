-- Plugin installer module for lazy.nvim integration
local M = {}

-- Check if lazy is available
local function is_lazy_available()
  return pcall(require, 'lazy')
end

-- Install plugins using lazy.nvim
local function install_plugins()
  local lazy_ok, lazy = pcall(require, 'lazy')
  if not lazy_ok then
    vim.notify("lazy.nvim is not available", vim.log.levels.ERROR)
    return
  end

  -- Run Lazy install
  vim.cmd('Lazy install')
end

-- Update plugins using lazy.nvim
local function update_plugins()
  local lazy_ok, lazy = pcall(require, 'lazy')
  if not lazy_ok then
    vim.notify("lazy.nvim is not available", vim.log.levels.ERROR)
    return
  end

  -- Reload plugins module then run Lazy sync
  package.loaded['user.plugins'] = nil
  require('user.plugins')
  vim.cmd('Lazy sync')
end

-- Clean plugins (remove unused)
local function clean_plugins()
  local lazy_ok, lazy = pcall(require, 'lazy')
  if not lazy_ok then
    vim.notify("lazy.nvim is not available", vim.log.levels.ERROR)
    return
  end
  
  -- Run Lazy clean
  vim.cmd('Lazy clean')
end

-- Status of plugins 
local function status_plugins()
  local lazy_ok, lazy = pcall(require, 'lazy')
  if not lazy_ok then
    vim.notify("lazy.nvim is not available", vim.log.levels.ERROR)
    return
  end
  
  -- Run Lazy show (status)
  vim.cmd('Lazy')
end

-- Create user commands for plugin management
function M.create_commands()
  -- Create user commands regardless of lazy.nvim availability
  -- They will check for lazy.nvim when executed
  
  -- Create user commands
  vim.api.nvim_create_user_command('InstallPlugins', install_plugins, {
    desc = 'Install all configured plugins'
  })
  
  vim.api.nvim_create_user_command('UpdatePlugins', update_plugins, {
    desc = 'Update all installed plugins'
  })
  
  vim.api.nvim_create_user_command('CleanPlugins', clean_plugins, {
    desc = 'Clean (remove) unused plugins'
  })
  
  vim.api.nvim_create_user_command('PluginStatus', status_plugins, {
    desc = 'Show status of installed plugins'
  })
end

return M 