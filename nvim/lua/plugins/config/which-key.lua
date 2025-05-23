-- which-key configuration

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local which_key = safe_require('which-key')
  
  if not which_key then
    return
  end

  which_key.setup({
    -- Basic which-key setup
  })
end

return M
