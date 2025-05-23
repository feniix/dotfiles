-- rainbow-delimiters configuration

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local rainbow_delimiters = safe_require('rainbow-delimiters')
  
  if rainbow_delimiters and rainbow_delimiters.strategy then
    vim.g.rainbow_delimiters = {
      strategy = {
        [''] = rainbow_delimiters.strategy['global'],
      },
      query = {
        [''] = 'rainbow-delimiters',
      },
    }
  end
end

return M
