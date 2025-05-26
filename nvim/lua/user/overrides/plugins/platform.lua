-- Platform-aware plugin override system
-- Provides platform-specific overrides for plugins

local M = {}

-- Lazy load dependencies to avoid circular requires
local function get_utils()
  return require('core.utils')
end

local function get_platform_config()
  return require('plugins.config.platform')
end

-- Apply platform-specific overrides to any plugin configuration
function M.apply_platform_overrides(plugin_name, base_config, user_config)
  local final_config = base_config or {}
  
  -- Get platform-specific configuration if available
  local platform_config = get_platform_config()
  local platform_getter = platform_config['get_' .. plugin_name .. '_config']
  if platform_getter and type(platform_getter) == 'function' then
    local platform_specific = platform_getter()
    final_config = vim.tbl_deep_extend('force', final_config, platform_specific)
  end
  
  -- Apply user overrides on top
  if user_config and type(user_config) == 'table' then
    final_config = vim.tbl_deep_extend('force', final_config, user_config)
  end
  
  return final_config
end

-- Get platform-specific plugin conditions
function M.get_platform_conditions()
  local utils = get_utils()
  return {
    -- Only load on platforms with git
    git_required = function()
      return utils.platform.command_available("git")
    end,
    
    -- Only load on platforms with make/cmake
    build_tools_required = function()
      return utils.platform.command_available("make") or utils.platform.command_available("cmake")
    end,
    
    -- Only load on GUI environments
    gui_only = function()
      return utils.platform.is_gui()
    end,
    
    -- Only load on specific platforms
    macos_only = function()
      return utils.platform.is_mac()
    end,
    
    linux_only = function()
      return utils.platform.is_linux()
    end,
    
    -- Only load if terminal supports true color
    true_color_required = function()
      return utils.platform.get_capabilities().true_color
    end,
    
    -- Only load if clipboard is available
    clipboard_required = function()
      return utils.platform.get_capabilities().clipboard
    end,
  }
end

-- Apply conditional loading based on platform
function M.apply_platform_conditions(plugin_spec, condition_name)
  local conditions = M.get_platform_conditions()
  local condition_func = conditions[condition_name]
  
  if condition_func and type(condition_func) == 'function' then
    plugin_spec.cond = condition_func
  end
  
  return plugin_spec
end

-- Enhanced override function with platform awareness
function M.override_with_platform(plugin_name, default_config, user_config, options)
  options = options or {}
  
  -- Start with default config
  local config = default_config or {}
  
  -- Apply platform-specific configuration
  config = M.apply_platform_overrides(plugin_name, config, nil)
  
  -- Apply user overrides
  if user_config and type(user_config) == 'table' then
    config = vim.tbl_deep_extend('force', config, user_config)
  end
  
  -- Apply platform conditions if specified
  if options.condition then
    config = M.apply_platform_conditions(config, options.condition)
  end
  
  return config
end

-- Get platform-specific key mappings
function M.get_platform_keymaps()
  local utils = get_utils()
  if utils.platform.is_mac() then
    -- macOS-specific keymaps (using Cmd key)
    return {
      { 'n', '<D-t>', '<cmd>Telescope find_files<cr>', { desc = 'Find Files (Cmd+T)' } },
      { 'n', '<D-p>', '<cmd>Telescope commands<cr>', { desc = 'Command Palette (Cmd+P)' } },
      { 'n', '<D-f>', '<cmd>Telescope live_grep<cr>', { desc = 'Search in Files (Cmd+F)' } },
    }
  else
    -- Linux-specific keymaps (using Ctrl key)
    return {
      { 'n', '<C-t>', '<cmd>Telescope find_files<cr>', { desc = 'Find Files (Ctrl+T)' } },
      { 'n', '<C-p>', '<cmd>Telescope commands<cr>', { desc = 'Command Palette (Ctrl+P)' } },
      { 'n', '<C-f>', '<cmd>Telescope live_grep<cr>', { desc = 'Search in Files (Ctrl+F)' } },
    }
  end
end

-- Setup platform-specific plugin configurations
function M.setup()
  local utils = get_utils()
  local platform_config = get_platform_config()
  
  -- Apply platform-specific keymaps
  local platform_keymaps = M.get_platform_keymaps()
  for _, keymap in ipairs(platform_keymaps) do
    vim.keymap.set(keymap[1], keymap[2], keymap[3], keymap[4])
  end
  
  -- Set platform-specific clipboard
  local clipboard_config = platform_config.get_clipboard_config()
  if clipboard_config and clipboard_config.providers then
    vim.g.clipboard = clipboard_config
  end
  
  local platform_name = utils.platform.is_mac() and "macOS" or "Linux"
  vim.notify('Applied platform-specific configurations for ' .. platform_name, vim.log.levels.INFO)
end

return M 