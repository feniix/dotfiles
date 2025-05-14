-- Plugin installer module for vim-plug integration
local M = {}

-- Check if vim-plug is available
local function is_vim_plug_available()
  return vim.fn.exists('*plug#begin') == 1
end

-- Install plugins using vim-plug
local function install_plugins()
  if not is_vim_plug_available() then
    vim.notify("vim-plug is not available", vim.log.levels.ERROR)
    return
  end

  -- Try to run PlugInstall
  local result = vim.fn.system('nvim --headless -c "PlugInstall --sync" -c "qa!"')
  vim.notify("Plugin installation complete. Restart Neovim to load new plugins.", vim.log.levels.INFO)
end

-- Update plugins using vim-plug
local function update_plugins()
  if not is_vim_plug_available() then
    vim.notify("vim-plug is not available", vim.log.levels.ERROR)
    return
  end

  -- Try to run PlugUpdate
  local result = vim.fn.system('nvim --headless -c "PlugUpdate --sync" -c "qa!"')
  vim.notify("Plugin update complete. Restart Neovim to load updated plugins.", vim.log.levels.INFO)
end

-- Clean plugins (remove unused)
local function clean_plugins()
  if not is_vim_plug_available() then
    vim.notify("vim-plug is not available", vim.log.levels.ERROR)
    return
  end
  
  -- Try to run PlugClean
  local result = vim.fn.system('nvim --headless -c "PlugClean!" -c "qa!"')
  vim.notify("Plugin cleanup complete.", vim.log.levels.INFO)
end

-- Status of plugins 
local function status_plugins()
  if not is_vim_plug_available() then
    vim.notify("vim-plug is not available", vim.log.levels.ERROR)
    return
  end
  
  -- Open a new buffer with PlugStatus
  vim.cmd("PlugStatus")
end

-- Create user commands for plugin management
function M.create_commands()
  -- Only create commands if vim-plug is available
  if not is_vim_plug_available() then
    vim.notify("vim-plug is not available, plugin installer commands not created", vim.log.levels.WARN)
    return
  end
  
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