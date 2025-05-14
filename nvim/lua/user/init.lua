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

-- Language modules to load in specific order (dependencies first)
-- Note: Some modules configure the same LSP server (e.g., yaml and kubernetes both use yamlls)
-- The order here determines which configuration takes precedence
local language_modules = {
  -- Basic language support first
  "json",        -- JSON support
  "yaml",        -- YAML support (should be before kubernetes)
  "terraform",   -- Terraform support
  "go",          -- Go support
  -- More specific language support that may build on basic ones
  "kubernetes",  -- Kubernetes support (builds on YAML)
  "typescript"   -- TypeScript support
}

-- Track LSP servers that have already been configured
local configured_lsp_servers = {}

-- Utility modules that should be loaded
local utility_modules = {
  "lsp",
  "lsp_common",
  "treesitter",
  "setup_treesitter",
  "plugin_installer",
  "config_test"
}

-- Track loaded modules for verification
local loaded_modules = {}

-- Setup a single module with error handling
local function setup_module(name, full_path, options)
  local ok, module = pcall(require, full_path)
  if not ok then
    vim.notify("Could not load module: " .. name .. " (" .. full_path .. ")", vim.log.levels.WARN)
    return false, nil
  end
  
  -- Track successful module loading
  loaded_modules[full_path] = true
  
  -- Check if the module has a setup function
  if type(module.setup) ~= "function" then
    vim.notify("Module " .. name .. " does not have a setup function", vim.log.levels.WARN)
    return false, module
  end
  
  -- Handle language modules that configure LSP servers
  if full_path:match("language%-support") then
    -- Pass the configured_lsp_servers table to language modules
    -- This allows them to check if a server is already configured
    if not options then
      options = {}
    end
    
    -- Add the configured_lsp_servers table to options
    options.configured_lsp_servers = configured_lsp_servers
  end
  
  -- Call the setup function with provided options or defaults
  local setup_ok, err = pcall(function()
    if options then
      module.setup(options)
    else
      module.setup()
    end
  end)
  
  if not setup_ok then
    vim.notify("Error setting up " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
    return false, module
  end
  
  return true, module
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
  
  -- Set up LSP Common module
  local _, lsp_common = setup_module("LSP Common", "user.lsp_common")
  if not lsp_common then
    vim.notify("Could not load LSP common module. Check your configuration.", vim.log.levels.ERROR)
  end
  
  -- Set up Treesitter
  local _, treesitter = setup_module("TreeSitter", "user.treesitter")
  
  -- Set up TreeSitter troubleshooting helpers
  if not vim.g.skip_treesitter_setup then
    local _, ts_setup = setup_module("TreeSitter Setup", "user.setup_treesitter")
    if ts_setup then
      -- Create command to manually install parsers
      vim.api.nvim_create_user_command('InstallTSParsers', function()
        ts_setup.install_parsers()
      end, { desc = 'Install TreeSitter parsers that might fail with the standard process' })
      
      -- Create command to specifically fix the vim parser
      vim.api.nvim_create_user_command('FixVimParser', function()
        ts_setup.install_vim_parser()
      end, { desc = 'Manually install the Vim TreeSitter parser' })
    end
  end
  
  -- Set up plugin installer
  if not vim.g.skip_plugin_installer then
    local _, plugin_installer = setup_module("Plugin Installer", "user.plugin_installer")
    if plugin_installer and plugin_installer.create_commands then
      plugin_installer.create_commands()
    end
  end
  
  -- Set up configuration tester
  local _, config_test = setup_module("Config Tester", "user.config_test")
  if config_test and config_test.create_commands then
    config_test.create_commands()
  end
  
  -- Set up language support modules
  for _, lang in ipairs(language_modules) do
    local full_path = "user.language-support." .. lang
    local options = {}
    
    -- Add common options for language modules
    if lang == "go" or lang == "terraform" or lang == "json" or lang == "yaml" then
      options = {
        auto_install_tools = true,
        auto_format_on_save = true
      }
    end
    
    -- Add schema support for JSON and YAML
    if lang == "json" or lang == "yaml" then
      options.use_schemas = true
    end
    
    -- Special options for Kubernetes
    if lang == "kubernetes" then
      options = {
        auto_install_tools = true,
        auto_format_on_save = true,
        use_schemas = true,
        operator_schemas = true,
        custom_schemas = {}
      }
    end
    
    local success, _ = setup_module(lang, full_path, options)
    if not success then
      vim.notify("Could not load " .. lang .. " module. Support for " .. lang .. " may be limited.", vim.log.levels.WARN)
    end
  end
  
  -- Create a command to verify loaded modules
  vim.api.nvim_create_user_command('CheckConfig', function()
    M.verify_loaded_modules()
  end, { desc = 'Verify all Neovim configuration modules are loaded' })
end

-- Function to verify all modules are loaded
function M.verify_loaded_modules()
  local missing_core = {}
  local missing_lang = {}
  local missing_utility = {}
  
  -- Check core modules
  for _, module in ipairs(core_modules) do
    local path = "user." .. module
    if not loaded_modules[path] then
      table.insert(missing_core, module)
    end
  end
  
  -- Check language modules
  for _, lang in ipairs(language_modules) do
    local path = "user.language-support." .. lang
    if not loaded_modules[path] then
      table.insert(missing_lang, lang)
    end
  end
  
  -- Check utility modules
  for _, util in ipairs(utility_modules) do
    local path = "user." .. util
    if not loaded_modules[path] then
      table.insert(missing_utility, util)
    end
  end
  
  -- Report results
  if #missing_core == 0 and #missing_lang == 0 and #missing_utility == 0 then
    vim.notify("✅ All configuration modules loaded successfully!", vim.log.levels.INFO)
  else
    if #missing_core > 0 then
      vim.notify("❌ Missing core modules: " .. table.concat(missing_core, ", "), vim.log.levels.ERROR)
    end
    if #missing_lang > 0 then
      vim.notify("❌ Missing language modules: " .. table.concat(missing_lang, ", "), vim.log.levels.ERROR)
    end
    if #missing_utility > 0 then
      vim.notify("❌ Missing utility modules: " .. table.concat(missing_utility, ", "), vim.log.levels.ERROR)
    end
  end
  
  -- Print loaded modules count
  local loaded_count = 0
  for _ in pairs(loaded_modules) do
    loaded_count = loaded_count + 1
  end
  
  vim.notify("📊 Loaded " .. loaded_count .. " modules total", vim.log.levels.INFO)
  
  return loaded_modules
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