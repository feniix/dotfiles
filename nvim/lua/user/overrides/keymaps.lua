-- User keymaps override
-- This module allows users to override or extend keymaps

local M = {}

-- Apply user keymap overrides
function M.setup(user_keymaps)
  if not user_keymaps or type(user_keymaps) ~= 'table' then
    return
  end
  
  local total_mappings = 0
  
  -- Apply keymaps for each mode
  for mode, mappings in pairs(user_keymaps) do
    if type(mappings) == 'table' then
      for key, mapping in pairs(mappings) do
        local rhs, opts
        
        -- Handle different mapping formats
        if type(mapping) == 'string' then
          rhs = mapping
          opts = {}
        elseif type(mapping) == 'table' then
          rhs = mapping[1] or mapping.rhs
          opts = vim.tbl_deep_extend('force', {}, mapping)
          opts[1] = nil
          opts.rhs = nil
        else
          rhs = mapping
          opts = {}
        end
        
        -- Set default options
        opts = vim.tbl_deep_extend('force', {
          silent = true,
          noremap = true,
        }, opts)
        
        -- Apply the mapping
        local ok, err = pcall(vim.keymap.set, mode, key, rhs, opts)
        if ok then
          total_mappings = total_mappings + 1
        else
          vim.notify(
            string.format('Failed to set keymap %s in mode %s: %s', key, mode, err),
            vim.log.levels.WARN
          )
        end
      end
    end
  end
  
  -- Notify user that custom keymaps were applied
  if total_mappings > 0 then
    vim.notify(
      string.format('Applied %d custom keymaps', total_mappings),
      vim.log.levels.INFO
    )
  end
end

-- Override function for advanced customization
function M.override(default_keymaps, user_keymaps)
  local result = vim.deepcopy(default_keymaps or {})
  
  -- Merge user keymaps
  for mode, mappings in pairs(user_keymaps or {}) do
    if not result[mode] then
      result[mode] = {}
    end
    
    for key, mapping in pairs(mappings) do
      result[mode][key] = mapping
    end
  end
  
  return result
end

return M 