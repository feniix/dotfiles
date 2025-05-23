-- Core module loader
-- This module loads all essential Neovim configuration

local M = {}

-- Load core modules in the correct order
function M.setup()
  -- Load utilities first (needed by other modules)
  require('core.utils').setup()
  
  -- Load core vim settings
  require('core.options').setup()
  
  -- Load global keymaps
  require('core.keymaps').setup()
  
  -- Load autocommands
  require('core.autocmds').setup()
end

return M 