-- Central initialization file for Neovim configuration
-- Handles loading of all modules in a consistent way

local M = {}

-- List of core modules to load in order (dependencies first)
local core_modules = {
  "options",    -- Editor options should be loaded first
  "plugins",    -- Plugin configuration
  "ui",         -- UI components (depends on plugins)
  "keymaps",    -- Keybindings (may depend on plugins)
  "completion", -- Completion system (depends on plugins)
}

-- Language modules to load (these generally depend on LSP being set up)
local language_modules = {
  "go",
  "terraform",
  "json",
  "yaml",
  "kubernetes",
  "typescript"
}

-- Setup a single module with error handling
local function setup_module(name, full_path)
  local ok, module = pcall(require, full_path)
  if not ok then
    vim.notify("Could not load module: " .. name .. " (" .. full_path .. ")", vim.log.levels.WARN)
    return false
  end
  
  -- Check if the module has a setup function
  if type(module.setup) ~= "function" then
    vim.notify("Module " .. name .. " does not have a setup function", vim.log.levels.WARN)
    return false
  end
  
  -- Call the setup function with default options
  local setup_ok, err = pcall(function()
    module.setup()
  end)
  
  if not setup_ok then
    vim.notify("Error setting up " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  
  return true
end

-- Initialize all core modules
function M.setup()
  -- Set up core modules first
  for _, module_name in ipairs(core_modules) do
    local full_path = "user." .. module_name
    local success = setup_module(module_name, full_path)
    
    if not success and module_name == "options" then
      vim.notify("Failed to load critical module: options. Using minimal defaults.", vim.log.levels.ERROR)
      -- Apply minimal defaults for options
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true
    end
  end
  
  -- Set up LSP first since language modules depend on it
  setup_module("LSP", "user.lsp")
  
  -- Set up language support modules
  for _, lang in ipairs(language_modules) do
    local full_path = "user.language-support." .. lang
    setup_module(lang, full_path)
  end
  
  -- Set up any additional modules
  setup_module("TreeSitter", "user.treesitter")
  setup_module("LSP Common", "user.lsp_common")
end

-- Individual module setup functions for manual loading
M.setup_options = function()
  setup_module("options", "user.options")
end

M.setup_plugins = function()
  setup_module("plugins", "user.plugins")
end

M.setup_ui = function()
  setup_module("UI", "user.ui")
end

M.setup_keymaps = function()
  setup_module("keymaps", "user.keymaps")
end

M.setup_completion = function()
  setup_module("completion", "user.completion")
end

M.setup_language = function(lang)
  if lang then
    setup_module(lang, "user.language-support." .. lang)
  else
    vim.notify("No language specified for setup_language", vim.log.levels.ERROR)
  end
end

return M 