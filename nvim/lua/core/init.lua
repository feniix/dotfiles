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
  
  -- Setup installer commands
  local installer_ok, installer = pcall(require, 'core.installer')
  if installer_ok then
    installer.setup_commands()
  end
  
  -- Apply user overrides to core modules
  local ok, user = pcall(require, 'user')
  if ok then
    user.setup_core_overrides()
  end
end

return M 