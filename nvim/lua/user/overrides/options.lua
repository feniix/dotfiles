-- User options override
-- This module allows users to override or extend core vim options

local M = {}

-- Apply user options overrides
function M.setup(user_options)
  if not user_options or type(user_options) ~= 'table' then
    return
  end
  
  local applied_count = 0
  
  -- Apply each user option
  for option, value in pairs(user_options) do
    local ok, err = pcall(function()
      -- Handle different option types
      if option:match('^g:') then
        -- Global variable
        local var_name = option:sub(3)
        vim.g[var_name] = value
      elseif option:match('^b:') then
        -- Buffer variable
        local var_name = option:sub(3)
        vim.b[var_name] = value
      elseif option:match('^w:') then
        -- Window variable
        local var_name = option:sub(3)
        vim.w[var_name] = value
      else
        -- Regular vim option
        vim.opt[option] = value
      end
    end)
    
    if ok then
      applied_count = applied_count + 1
    else
      vim.notify(
        string.format('Failed to set option %s: %s', option, err),
        vim.log.levels.WARN
      )
    end
  end
  
  -- Notify user that custom options were applied
  if applied_count > 0 then
    vim.notify(
      string.format('Applied %d custom vim options', applied_count),
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