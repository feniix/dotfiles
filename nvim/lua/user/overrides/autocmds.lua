-- User autocmds override
-- This module allows users to override or extend autocommands

local M = {}

-- Apply user autocommand overrides
function M.setup(user_autocmds)
  if not user_autocmds or type(user_autocmds) ~= 'table' then
    return
  end
  
  local total_autocmds = 0
  
  -- Create a user autocmd group to organize user-defined autocommands
  local user_group = vim.api.nvim_create_augroup('UserOverrides', { clear = true })
  
  for _, autocmd in ipairs(user_autocmds) do
    if type(autocmd) == 'table' and autocmd.event then
      local opts = vim.tbl_deep_extend('force', {}, autocmd)
      
      -- Set the group for organization
      opts.group = user_group
      
      -- Apply the autocommand
      local ok, err = pcall(vim.api.nvim_create_autocmd, autocmd.event, opts)
      if ok then
        total_autocmds = total_autocmds + 1
      else
        vim.notify(
          string.format('Failed to create autocmd for event %s: %s', 
            vim.inspect(autocmd.event), err),
          vim.log.levels.WARN
        )
      end
    end
  end
  
  -- Notify user that custom autocmds were applied
  if total_autocmds > 0 then
    vim.notify(
      string.format('Applied %d custom autocommands', total_autocmds),
      vim.log.levels.INFO
    )
  end
end

-- Override function for advanced customization
function M.override(default_autocmds, user_autocmds)
  local result = vim.deepcopy(default_autocmds or {})
  
  -- Add user autocmds to the list
  if user_autocmds and type(user_autocmds) == 'table' then
    vim.list_extend(result, user_autocmds)
  end
  
  return result
end

return M 