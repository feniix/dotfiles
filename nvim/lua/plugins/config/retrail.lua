-- retrail configuration

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local retrail = safe_require('retrail')
  
  if not retrail then
    return
  end

  retrail.setup({
    trim = {
      auto = true,
      whitespace = true,
      blanklines = false,
    }
  })
end

return M
