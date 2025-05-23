-- Plugin management tools and utilities
-- Migrated from user/plugin_installer.lua

local M = {}

-- Check if lazy is available
local function is_lazy_available()
  return pcall(require, 'lazy')
end

-- Install plugins using lazy.nvim
local function install_plugins()
  local safe_require = _G.safe_require or require
  local lazy = safe_require('lazy')
  
  if not lazy then
    vim.notify("lazy.nvim is not available", vim.log.levels.ERROR)
    return
  end

  -- Run Lazy install
  vim.cmd('Lazy install')
end

-- Update plugins using lazy.nvim
local function update_plugins()
  local safe_require = _G.safe_require or require
  local lazy = safe_require('lazy')
  
  if not lazy then
    vim.notify("lazy.nvim is not available", vim.log.levels.ERROR)
    return
  end

  -- Reload plugins module then run Lazy sync
  package.loaded['plugins.init'] = nil
  require('plugins.init')
  vim.cmd('Lazy sync')
end

-- Clean plugins (remove unused)
local function clean_plugins()
  local safe_require = _G.safe_require or require
  local lazy = safe_require('lazy')
  
  if not lazy then
    vim.notify("lazy.nvim is not available", vim.log.levels.ERROR)
    return
  end
  
  -- Run Lazy clean
  vim.cmd('Lazy clean')
end

-- Status of plugins 
local function status_plugins()
  local safe_require = _G.safe_require or require
  local lazy = safe_require('lazy')
  
  if not lazy then
    vim.notify("lazy.nvim is not available", vim.log.levels.ERROR)
    return
  end
  
  -- Run Lazy show (status)
  vim.cmd('Lazy')
end

-- Health check for plugins
local function health_check()
  vim.cmd('checkhealth')
end

-- Reload Neovim configuration
local function reload_config()
  -- Clear loaded modules
  for name, _ in pairs(package.loaded) do
    if name:match('^core') or name:match('^plugins') then
      package.loaded[name] = nil
    end
  end
  
  -- Reload init file
  dofile(vim.env.MYVIMRC)
  vim.notify("Configuration reloaded", vim.log.levels.INFO)
end

-- Create user commands for plugin management
function M.setup()
  -- Create user commands for plugin management
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
  
  vim.api.nvim_create_user_command('HealthCheck', health_check, {
    desc = 'Run Neovim health check'
  })
  
  vim.api.nvim_create_user_command('ReloadConfig', reload_config, {
    desc = 'Reload Neovim configuration'
  })
  
  -- Set up keymaps for quick access
  M.setup_keymaps()
end

function M.setup_keymaps()
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true }
  
  -- Plugin management keymaps
  keymap('n', '<leader>pi', install_plugins, vim.tbl_extend('force', opts, { desc = 'Install plugins' }))
  keymap('n', '<leader>pu', update_plugins, vim.tbl_extend('force', opts, { desc = 'Update plugins' }))
  keymap('n', '<leader>pc', clean_plugins, vim.tbl_extend('force', opts, { desc = 'Clean plugins' }))
  keymap('n', '<leader>ps', status_plugins, vim.tbl_extend('force', opts, { desc = 'Plugin status' }))
  keymap('n', '<leader>ph', health_check, vim.tbl_extend('force', opts, { desc = 'Health check' }))
  keymap('n', '<leader>pr', reload_config, vim.tbl_extend('force', opts, { desc = 'Reload config' }))
end

return M 