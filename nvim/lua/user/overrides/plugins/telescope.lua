-- User telescope override
-- This module allows users to override telescope configuration

local M = {}

-- Apply user telescope configuration overrides
function M.setup(user_config)
  if not user_config or type(user_config) ~= 'table' then
    return
  end
  
  -- Check if telescope is available
  local ok, telescope = pcall(require, 'telescope')
  if not ok then
    vim.notify('Telescope not available for user override', vim.log.levels.WARN)
    return
  end
  
  -- Get current telescope configuration
  local current_config = telescope._config or {}
  
  -- Merge user configuration with current config
  local merged_config = vim.tbl_deep_extend('force', current_config, user_config)
  
  -- Apply the merged configuration
  telescope.setup(merged_config)
  
  vim.notify('Applied user telescope configuration overrides', vim.log.levels.INFO)
end

-- Override function for advanced customization
function M.override(default_config, user_config)
  if not user_config or type(user_config) ~= 'table' then
    return default_config
  end
  
  return vim.tbl_deep_extend('force', default_config or {}, user_config)
end

return M 