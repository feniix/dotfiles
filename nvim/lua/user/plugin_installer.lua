-- Plugin installer module for Packer integration
local M = {}

-- Check if packer is available
local function is_packer_available()
  return pcall(require, 'packer')
end

-- Install plugins using Packer
local function install_plugins()
  local packer_ok, packer = pcall(require, 'packer')
  if not packer_ok then
    vim.notify("Packer is not available", vim.log.levels.ERROR)
    return
  end

  -- Run PackerInstall
  vim.cmd('PackerInstall')
end

-- Update plugins using Packer
local function update_plugins()
  local packer_ok, packer = pcall(require, 'packer')
  if not packer_ok then
    vim.notify("Packer is not available", vim.log.levels.ERROR)
    return
  end

  -- Reload plugins module then run PackerSync
  package.loaded['user.plugins'] = nil
  require('user.plugins')
  vim.cmd('PackerSync')
end

-- Clean plugins (remove unused)
local function clean_plugins()
  local packer_ok, packer = pcall(require, 'packer')
  if not packer_ok then
    vim.notify("Packer is not available", vim.log.levels.ERROR)
    return
  end
  
  -- Run PackerClean
  vim.cmd('PackerClean')
end

-- Status of plugins 
local function status_plugins()
  local packer_ok, packer = pcall(require, 'packer')
  if not packer_ok then
    vim.notify("Packer is not available", vim.log.levels.ERROR)
    return
  end
  
  -- Run PackerStatus
  vim.cmd('PackerStatus')
end

-- Create user commands for plugin management
function M.create_commands()
  -- Create user commands regardless of Packer availability
  -- They will check for Packer when executed
  
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