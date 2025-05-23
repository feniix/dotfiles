-- dap configuration

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local dap = safe_require('dap')
  
  if not dap then
    return
  end

  -- Basic DAP setup - TODO: migrate from user.dap
end

return M
