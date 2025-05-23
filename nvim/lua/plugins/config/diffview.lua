-- diffview configuration

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local diffview = safe_require('diffview')
  
  if not diffview then
    return
  end

  diffview.setup({
    -- Basic diffview setup - TODO: migrate from user.diffview
  })
end

return M
