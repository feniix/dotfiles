-- Comment.nvim configuration

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local comment = safe_require('Comment')
  
  if not comment then
    return
  end

  local comment_config = {
    -- Basic Comment.nvim setup
  }
  
  -- Add ts-context-commentstring integration if available
  if safe_require('ts_context_commentstring.integrations.comment_nvim') then
    local ts_context = require('ts_context_commentstring.integrations.comment_nvim')
    comment_config.pre_hook = ts_context.create_pre_hook()
  end
  
  comment.setup(comment_config)
end

return M
