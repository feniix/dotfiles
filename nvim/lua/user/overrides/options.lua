-- User options override
-- This module allows users to override or extend core vim options

local M = {}

-- Apply user options overrides
function M.setup(user_options)
  if not user_options or type(user_options) ~= 'table' then
    return
  end
  
  -- Apply each user option
  for option, value in pairs(user_options) do
    local ok, err = pcall(function()
      vim.opt[option] = value
    end)
    
    if not ok then
      vim.notify(
        string.format('Failed to set option %s: %s', option, err),
        vim.log.levels.WARN
      )
    end
  end
  
  -- Notify user that custom options were applied
  local option_count = vim.tbl_count(user_options)
  if option_count > 0 then
    vim.notify(
      string.format('Applied %d custom vim options', option_count),
      vim.log.levels.INFO
    )
  end
end

-- Override function for advanced customization
-- This allows users to define complex option logic
function M.override(default_options, user_options)
  local result = vim.deepcopy(default_options or {})
  
  -- Merge user options
  for option, value in pairs(user_options or {}) do
    result[option] = value
  end
  
  return result
end

return M 