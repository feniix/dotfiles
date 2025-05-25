-- User telescope override with platform awareness
-- This module allows users to override telescope configuration with platform-specific settings

local utils = require('core.utils')
local platform_config = require('plugins.config.platform')
local M = {}

-- Apply user telescope configuration overrides
function M.setup(user_config)
  -- Get platform-specific base configuration
  local base_config = platform_config.get_telescope_config()
  
  -- Merge with user config if provided
  local final_config = base_config
  if user_config and type(user_config) == 'table' then
    final_config = vim.tbl_deep_extend('force', base_config, user_config)
  end
  
  -- Check if telescope is available
  local ok, telescope = pcall(require, 'telescope')
  if not ok then
    vim.notify('Telescope not available for user override', vim.log.levels.WARN)
    return
  end
  
  -- Apply the configuration
  telescope.setup(final_config)
  
  local platform_info = utils.platform.is_mac() and "macOS" or "Linux"
  vim.notify('Applied telescope configuration for ' .. platform_info, vim.log.levels.INFO)
end

-- Override function for advanced customization
function M.override(default_config, user_config)
  if not user_config or type(user_config) ~= 'table' then
    return default_config
  end
  
  return vim.tbl_deep_extend('force', default_config or {}, user_config)
end

return M 