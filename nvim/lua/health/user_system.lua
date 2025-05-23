-- Health check module for user override system
-- This module validates the integrity of user customizations and overrides

local M = {}

-- Define health check module (compatible with both old and new APIs)
local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

-- Safe require function
local function safe_require(module)
  local success, result = pcall(require, module)
  return success and result or nil
end

-- Check if file exists
local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

-- Check user module initialization
local function check_user_init()
  start("User Module Initialization")
  
  local user = safe_require("user")
  if not user then
    info("User module is not loaded (this is optional)")
    return
  end
  
  ok("User module is loaded successfully")
  
  -- Check if setup function exists
  if user.setup and type(user.setup) == "function" then
    ok("user.setup function is available")
  else
    warn("user.setup function is missing")
  end
  
  -- Check if user is integrated with the core system
  if _G.user_config_loaded then
    ok("User configuration integration is working")
  else
    info("User configuration integration flag not found")
  end
end

-- Check user configuration
local function check_user_config()
  start("User Configuration")
  
  -- Check if config file exists
  local config_path = vim.fn.stdpath("config") .. "/lua/user/config.lua"
  local example_path = vim.fn.stdpath("config") .. "/lua/user/config.lua.example"
  
  if file_exists(config_path) then
    ok("User configuration file exists")
    
    -- Try to load the config
    local user_config = safe_require("user.config")
    if user_config then
      ok("User configuration is loaded successfully")
      
      -- Check config structure
      if type(user_config) == "table" then
        ok("User configuration has valid table structure")
        
        -- Check for common config sections
        local sections = {"core", "plugins", "custom"}
        for _, section in ipairs(sections) do
          if user_config[section] then
            info("User configuration has '" .. section .. "' section")
          end
        end
        
        -- Check if user config has any customizations
        local has_customizations = false
        for key, value in pairs(user_config) do
          if key ~= "_G" and type(value) ~= "function" then
            has_customizations = true
            break
          end
        end
        
        if has_customizations then
          ok("User configuration contains customizations")
        else
          info("User configuration is mostly default (no custom settings detected)")
        end
      else
        warn("User configuration does not return a table")
      end
    else
      warn("User configuration file exists but could not be loaded")
    end
  elseif file_exists(example_path) then
    info("User configuration example file exists")
    info("To customize: cp " .. example_path .. " " .. config_path)
  else
    info("No user configuration found (this is optional)")
  end
end

-- Check user overrides
local function check_user_overrides()
  start("User Override System")
  
  local overrides_dir = vim.fn.stdpath("config") .. "/lua/user/overrides"
  
  if vim.fn.isdirectory(overrides_dir) == 1 then
    ok("User overrides directory exists")
    
    -- Check individual override files
    local override_files = {
      { name = "options", desc = "Vim options overrides" },
      { name = "keymaps", desc = "Keymap overrides" },
      { name = "autocmds", desc = "Autocommand overrides" },
    }
    
    for _, override in ipairs(override_files) do
      local override_path = overrides_dir .. "/" .. override.name .. ".lua"
      if file_exists(override_path) then
        ok("User " .. override.desc .. " file exists")
        
        -- Try to load the override
        local override_module = safe_require("user.overrides." .. override.name)
        if override_module then
          ok("User " .. override.desc .. " is loaded successfully")
          
          -- Check if it's a valid table
          if type(override_module) == "table" then
            ok("User " .. override.desc .. " has valid structure")
          else
            warn("User " .. override.desc .. " does not return a table")
          end
        else
          warn("User " .. override.desc .. " exists but could not be loaded")
        end
      else
        info("User " .. override.desc .. " is not configured")
      end
    end
    
    -- Check plugin overrides directory
    local plugin_overrides_dir = overrides_dir .. "/plugins"
    if vim.fn.isdirectory(plugin_overrides_dir) == 1 then
      ok("User plugin overrides directory exists")
      
      -- Count plugin override files
      local plugin_overrides = vim.fn.glob(plugin_overrides_dir .. "/*.lua", false, true)
      if #plugin_overrides > 0 then
        ok("Found " .. #plugin_overrides .. " plugin override files")
        
        -- Test loading a few plugin overrides
        for i, override_file in ipairs(plugin_overrides) do
          if i > 3 then break end  -- Only test first 3
          
          local filename = vim.fn.fnamemodify(override_file, ":t:r")
          local override_module = safe_require("user.overrides.plugins." .. filename)
          if override_module then
            ok("Plugin override '" .. filename .. "' loads successfully")
          else
            warn("Plugin override '" .. filename .. "' could not be loaded")
          end
        end
      else
        info("No plugin overrides configured")
      end
    else
      info("User plugin overrides directory does not exist")
    end
  else
    info("User overrides directory does not exist")
  end
end

-- Check user modules
local function check_user_modules()
  start("User Custom Modules")
  
  local modules_dir = vim.fn.stdpath("config") .. "/lua/user/modules"
  
  if vim.fn.isdirectory(modules_dir) == 1 then
    ok("User modules directory exists")
    
    -- Find custom module files
    local module_files = vim.fn.glob(modules_dir .. "/*.lua", false, true)
    
    if #module_files > 0 then
      ok("Found " .. #module_files .. " custom user modules")
      
      -- Test loading custom modules
      for _, module_file in ipairs(module_files) do
        local filename = vim.fn.fnamemodify(module_file, ":t:r")
        
        -- Skip example files
        if not filename:match("%.example$") then
          local module = safe_require("user.modules." .. filename)
          if module then
            ok("Custom module '" .. filename .. "' loads successfully")
            
            -- Check if it has a setup function
            if module.setup and type(module.setup) == "function" then
              ok("Custom module '" .. filename .. "' has setup function")
            else
              info("Custom module '" .. filename .. "' does not have setup function")
            end
          else
            warn("Custom module '" .. filename .. "' could not be loaded")
          end
        end
      end
    else
      info("No custom user modules found")
    end
    
    -- Check for example files
    local example_files = vim.fn.glob(modules_dir .. "/*.example", false, true)
    if #example_files > 0 then
      info("Found " .. #example_files .. " example module files")
    end
  else
    info("User modules directory does not exist")
  end
end

-- Check user integration with core system
local function check_integration()
  start("User-Core Integration")
  
  -- Check if user overrides are being applied to core modules
  local integration_checks = {
    {
      name = "Core Options Integration",
      check = function()
        local core_utils = safe_require("core.utils")
        if core_utils and core_utils.merge_user_options then
          return true, "Core options merger is available"
        end
        return false, "Core options merger not found"
      end
    },
    {
      name = "Core Keymaps Integration", 
      check = function()
        local core_utils = safe_require("core.utils")
        if core_utils and core_utils.merge_user_keymaps then
          return true, "Core keymaps merger is available"
        end
        return false, "Core keymaps merger not found"
      end
    },
    {
      name = "Plugin Override Integration",
      check = function()
        local plugins = safe_require("plugins")
        if plugins and plugins.apply_user_overrides then
          return true, "Plugin override system is available"
        end
        return false, "Plugin override system not found"
      end
    }
  }
  
  for _, check in ipairs(integration_checks) do
    local success, message = check.check()
    if success then
      ok(check.name .. ": " .. message)
    else
      warn(check.name .. ": " .. message)
    end
  end
  
  -- Check if user post-setup hooks are working
  if _G.user_post_setup_complete then
    ok("User post-setup hooks have been executed")
  else
    info("User post-setup hooks status unknown")
  end
  
  -- Check for user environment variables or globals
  local user_globals = {}
  for key, _ in pairs(_G) do
    if key:match("^user_") or key:match("^USER_") then
      table.insert(user_globals, key)
    end
  end
  
  if #user_globals > 0 then
    info("Found " .. #user_globals .. " user-related globals")
    if #user_globals <= 5 then
      info("User globals: " .. table.concat(user_globals, ", "))
    end
  end
end

-- Check user documentation and help
local function check_user_docs()
  start("User Documentation")
  
  local docs_to_check = {
    { path = "user/README.md", desc = "User system documentation" },
    { path = "user/config.lua.example", desc = "Configuration example" },
    { path = "user/modules/my_custom_module.lua.example", desc = "Custom module example" },
  }
  
  local config_root = vim.fn.stdpath("config") .. "/lua"
  
  for _, doc in ipairs(docs_to_check) do
    local full_path = config_root .. "/" .. doc.path
    if file_exists(full_path) then
      ok(doc.desc .. " is available")
    else
      info(doc.desc .. " is not found")
    end
  end
  
  -- Check if user commands are available
  local user_commands = vim.api.nvim_get_commands({})
  local user_command_count = 0
  
  for cmd_name, _ in pairs(user_commands) do
    if cmd_name:match("^User") or cmd_name:match("^Custom") then
      user_command_count = user_command_count + 1
    end
  end
  
  if user_command_count > 0 then
    ok("Found " .. user_command_count .. " user-related commands")
  else
    info("No user-related commands found")
  end
end

-- Check user health system itself
local function check_user_health_system()
  start("User Health Check System")
  
  -- Check if the original user health module exists
  local user_health = safe_require("user.health")
  if user_health then
    ok("User health module is loaded")
    
    if user_health.check and type(user_health.check) == "function" then
      ok("User health check function is available")
    else
      warn("User health check function is missing")
    end
    
    if user_health.setup and type(user_health.setup) == "function" then
      ok("User health setup function is available")
    else
      info("User health setup function is not available")
    end
  else
    warn("User health module could not be loaded")
  end
  
  -- Check health integration
  local health_user = safe_require("health.user")
  if health_user then
    ok("Health-User integration module is available")
  else
    warn("Health-User integration module is missing")
  end
  
  -- Test if checkhealth user works
  local has_checkhealth = vim.fn.exists(":checkhealth") == 2
  if has_checkhealth then
    ok("Neovim checkhealth command is available")
    info("Run ':checkhealth user' to see user-specific health checks")
  else
    warn("Neovim checkhealth command is not available")
  end
end

-- Main health check function
function M.check()
  check_user_init()
  check_user_config()
  check_user_overrides()
  check_user_modules()
  check_integration()
  check_user_docs()
  check_user_health_system()
end

return M 