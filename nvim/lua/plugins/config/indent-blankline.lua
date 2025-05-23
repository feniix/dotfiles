-- Indent-blankline configuration

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local ibl = safe_require('ibl')
  
  if not ibl then
    return
  end

  ibl.setup({
    -- Basic configuration
    indent = {
      char = "│",
    },
    scope = {
      enabled = true,
    },
  })
end

return M
