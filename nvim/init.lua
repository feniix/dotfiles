-- New Neovim Configuration Entry Point
-- Reorganized with better separation of concerns

-- Check if we're running in Neovim
if vim.fn.has('nvim') == 0 then
  return
end

-- Load core functionality first
require('core').setup()

-- Load plugin management
require('plugins').setup()
