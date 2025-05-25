-- User override system
-- This module provides hooks for users to customize any aspect of the configuration

local M = {}

-- User configuration namespace
local user_config = {}

-- Load user configuration if it exists
local function load_user_config()
  local ok, config = pcall(require, 'user.config')
  if ok then
    user_config = config or {}
  end
  return user_config
end

-- Apply user overrides to core modules
function M.setup_core_overrides()
  local config = load_user_config()
  
  -- User can override options
  if config.options then
    local options_override = require('user.overrides.options')
    if options_override and options_override.setup then
      options_override.setup(config.options)
    end
  end
  
  -- User can override keymaps
  if config.keymaps then
    local keymaps_override = require('user.overrides.keymaps')
    if keymaps_override and keymaps_override.setup then
      keymaps_override.setup(config.keymaps)
    end
  end
  
  -- User can override autocmds
  if config.autocmds then
    local autocmds_override = require('user.overrides.autocmds')
    if autocmds_override and autocmds_override.setup then
      autocmds_override.setup(config.autocmds)
    end
  end
end

-- Apply user overrides to plugin specs
function M.get_plugin_overrides()
  local config = load_user_config()
  local overrides = {}
  
  -- User can add custom plugins
  if config.plugins and config.plugins.specs then
    for category, specs in pairs(config.plugins.specs) do
      overrides[category] = specs
    end
  end
  
  return overrides
end

-- Apply user overrides to plugin configurations
function M.setup_plugin_overrides()
  local config = load_user_config()
  
  -- User can override plugin configurations
  if config.plugins and config.plugins.config then
    for plugin_name, plugin_config in pairs(config.plugins.config) do
      local override_path = string.format('user.overrides.plugins.%s', plugin_name)
      local ok, override_module = pcall(require, override_path)
      if ok and override_module and override_module.setup then
        override_module.setup(plugin_config)
      end
    end
  end
end

-- Allow users to customize lazy.nvim setup
function M.get_lazy_config_overrides()
  local config = load_user_config()
  return config.lazy_config or {}
end

-- Run user post-setup hooks
function M.run_post_setup_hooks()
  local config = load_user_config()
  
  -- User can define custom post-setup logic
  if config.post_setup and type(config.post_setup) == 'function' then
    config.post_setup()
  end
  
  -- Load any additional user modules
  if config.modules then
    for _, module_name in ipairs(config.modules) do
      local ok, module = pcall(require, 'user.modules.' .. module_name)
      if ok and module and module.setup then
        module.setup()
      end
    end
  end
end

-- Utility function to safely override a table
function M.safe_override(original, override)
  if type(override) ~= 'table' then
    return original
  end
  
  return vim.tbl_deep_extend('force', vim.deepcopy(original or {}), override)
end

-- Utility function to safely extend a list
function M.safe_extend(original, extension)
  if type(extension) ~= 'table' then
    return original
  end
  
  local result = vim.deepcopy(original or {})
  vim.list_extend(result, extension)
  return result
end

-- Helper function to check if user override exists
function M.has_override(module_path)
  local ok, _ = pcall(require, 'user.overrides.' .. module_path)
  return ok
end

-- Helper function to apply user override if it exists
function M.apply_override(module_path, default_config, user_config)
  if not M.has_override(module_path) then
    return default_config
  end
  
  local override_module = require('user.overrides.' .. module_path)
  if override_module and override_module.override then
    return override_module.override(default_config, user_config)
  end
  
  return default_config
end

return M 