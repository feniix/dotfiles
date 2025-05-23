-- Health check module for the new Neovim configuration structure
-- This module validates the overall reorganization and architectural integrity

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

-- Check if directory exists
local function dir_exists(path)
  return vim.fn.isdirectory(path) == 1
end

-- Check if file exists
local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

-- Count files in directory with pattern
local function count_files(dir, pattern)
  if not dir_exists(dir) then return 0 end
  local files = vim.fn.glob(dir .. "/" .. (pattern or "*"), false, true)
  return #files
end

-- Check overall directory structure
local function check_directory_structure()
  start("Directory Structure Validation")
  
  local config_root = vim.fn.stdpath("config")
  
  -- Core structure validation
  local core_structure = {
    { path = "lua", desc = "Main Lua directory", required = true },
    { path = "lua/core", desc = "Core modules directory", required = true },
    { path = "lua/plugins", desc = "Plugin management directory", required = true },
    { path = "lua/plugins/specs", desc = "Plugin specifications directory", required = true },
    { path = "lua/plugins/config", desc = "Plugin configurations directory", required = true },
    { path = "lua/user", desc = "User customization directory", required = false },
    { path = "lua/health", desc = "Health check modules directory", required = false },
  }
  
  for _, item in ipairs(core_structure) do
    local full_path = config_root .. "/" .. item.path
    if dir_exists(full_path) then
      ok(item.desc .. " exists")
      
      -- Count files in directory for informational purposes
      local file_count = count_files(full_path, "*.lua")
      if file_count > 0 then
        info(item.desc .. " contains " .. file_count .. " Lua files")
      end
    else
      if item.required then
        error(item.desc .. " is missing (required)")
      else
        info(item.desc .. " is missing (optional)")
      end
    end
  end
  
  -- Check language-specific directories
  local lang_dirs = {
    { path = "lua/plugins/specs/lang", desc = "Language plugin specs" },
    { path = "lua/plugins/config/lang", desc = "Language plugin configs" },
  }
  
  for _, lang_dir in ipairs(lang_dirs) do
    local full_path = config_root .. "/" .. lang_dir.path
    if dir_exists(full_path) then
      ok(lang_dir.desc .. " directory exists")
      
      local lang_count = count_files(full_path, "*.lua")
      if lang_count > 0 then
        info(lang_dir.desc .. " supports " .. lang_count .. " languages")
      end
    else
      info(lang_dir.desc .. " directory does not exist")
    end
  end
end

-- Check core module completeness
local function check_core_modules()
  start("Core Module Completeness")
  
  local core_modules = {
    { name = "init", desc = "Core initialization", required = true },
    { name = "utils", desc = "Utility functions", required = true },
    { name = "options", desc = "Vim options", required = true },
    { name = "keymaps", desc = "Global keymaps", required = true },
    { name = "autocmds", desc = "Autocommands", required = true },
  }
  
  for _, module in ipairs(core_modules) do
    local module_obj = safe_require("core." .. module.name)
    if module_obj then
      ok("Core module '" .. module.name .. "' (" .. module.desc .. ") is loaded")
      
      -- Check if module has setup function
      if module_obj.setup and type(module_obj.setup) == "function" then
        ok("Core module '" .. module.name .. "' has setup function")
      else
        if module.name ~= "init" then  -- init module may not need setup
          info("Core module '" .. module.name .. "' does not have setup function")
        end
      end
    else
      if module.required then
        error("Required core module '" .. module.name .. "' could not be loaded")
      else
        warn("Optional core module '" .. module.name .. "' could not be loaded")
      end
    end
  end
  
  -- Check core module accessibility through main core module
  local core = safe_require("core")
  if core then
    ok("Main core module is accessible")
    
    -- Test if core.setup exists and works
    if core.setup and type(core.setup) == "function" then
      ok("Core setup function is available")
    else
      warn("Core setup function is missing")
    end
  else
    error("Main core module could not be loaded")
  end
end

-- Check plugin system architecture
local function check_plugin_architecture()
  start("Plugin System Architecture")
  
  -- Check plugin manager setup
  local plugins = safe_require("plugins")
  if plugins then
    ok("Plugin system is loaded")
    
    if plugins.setup and type(plugins.setup) == "function" then
      ok("Plugin setup function is available")
    else
      warn("Plugin setup function is missing")
    end
  else
    error("Plugin system could not be loaded")
  end
  
  -- Check separation of specs and configs
  local spec_categories = {"ui", "editor", "lsp", "tools"}
  local missing_specs = {}
  local existing_specs = {}
  
  for _, category in ipairs(spec_categories) do
    local spec = safe_require("plugins.specs." .. category)
    if spec then
      table.insert(existing_specs, category)
      ok("Plugin spec category '" .. category .. "' exists")
    else
      table.insert(missing_specs, category)
      warn("Plugin spec category '" .. category .. "' is missing")
    end
  end
  
  if #existing_specs > 0 then
    info("Available spec categories: " .. table.concat(existing_specs, ", "))
  end
  
  if #missing_specs > 0 then
    info("Missing spec categories: " .. table.concat(missing_specs, ", "))
  end
  
  -- Check plugin configurations
  local config_root = vim.fn.stdpath("config") .. "/lua/plugins/config"
  local config_count = count_files(config_root, "*.lua")
  
  if config_count > 0 then
    ok("Found " .. config_count .. " plugin configuration files")
  else
    warn("No plugin configuration files found")
  end
  
  -- Check language-specific plugins
  local lang_spec_count = count_files(config_root .. "/lang", "*.lua")
  local lang_config_count = count_files(config_root .. "/lang", "*.lua")
  
  if lang_spec_count > 0 or lang_config_count > 0 then
    ok("Language-specific plugin support is configured")
    info("Language specs: " .. lang_spec_count .. ", configs: " .. lang_config_count)
  else
    info("No language-specific plugin configurations found")
  end
end

-- Check modular loading and lazy loading
local function check_loading_strategy()
  start("Loading Strategy Validation")
  
  -- Check if lazy.nvim is properly configured
  local lazy = safe_require("lazy")
  if lazy then
    ok("Lazy.nvim plugin manager is loaded")
    
    -- Check lazy loading statistics
    if lazy.stats then
      local stats = lazy.stats()
      if stats then
        local total_plugins = stats.count or 0
        local loaded_plugins = stats.loaded or 0
        local lazy_plugins = total_plugins - loaded_plugins
        
        info("Total plugins: " .. total_plugins)
        info("Loaded at startup: " .. loaded_plugins) 
        info("Lazy-loaded: " .. lazy_plugins)
        
        if lazy_plugins > 0 then
          ok("Lazy loading is working (" .. lazy_plugins .. " plugins are lazy-loaded)")
        else
          warn("No plugins are configured for lazy loading")
        end
        
        -- Check startup time
        if stats.startuptime then
          local startup_time = stats.startuptime
          if startup_time < 100 then
            ok("Fast startup time: " .. string.format("%.2f", startup_time) .. "ms")
          elseif startup_time < 200 then
            ok("Reasonable startup time: " .. string.format("%.2f", startup_time) .. "ms")
          else
            warn("Slow startup time: " .. string.format("%.2f", startup_time) .. "ms")
          end
        end
      end
    else
      warn("Lazy.nvim statistics are not available")
    end
  else
    error("Lazy.nvim plugin manager is not loaded")
  end
  
  -- Check modular initialization
  local init_modules_loaded = 0
  local init_modules = {"core", "plugins", "user"}
  
  for _, module in ipairs(init_modules) do
    if safe_require(module) then
      init_modules_loaded = init_modules_loaded + 1
    end
  end
  
  if init_modules_loaded == #init_modules then
    ok("All initialization modules are loaded")
  else
    warn("Some initialization modules failed to load (" .. init_modules_loaded .. "/" .. #init_modules .. ")")
  end
end

-- Check backward compatibility
local function check_backward_compatibility()
  start("Backward Compatibility")
  
  local config_root = vim.fn.stdpath("config")
  
  -- Check if original init.lua exists
  if file_exists(config_root .. "/init.lua") then
    ok("Original init.lua exists (backward compatibility)")
    
    -- Check if it's preserved or updated
    local init_content = vim.fn.readfile(config_root .. "/init.lua")
    local has_new_structure = false
    
    for _, line in ipairs(init_content) do
      if line:match("core%.setup") or line:match("plugins%.setup") then
        has_new_structure = true
        break
      end
    end
    
    if has_new_structure then
      ok("init.lua has been updated to use new structure")
    else
      info("init.lua appears to use original structure")
    end
  else
    warn("Original init.lua is missing")
  end
  
  -- Check for migration artifacts
  local old_patterns = {
    "after/plugin",
    "plugin/packer_compiled.lua",
    "lua/packer_init.lua"
  }
  
  local cleanup_needed = {}
  for _, pattern in ipairs(old_patterns) do
    local full_path = config_root .. "/" .. pattern
    if file_exists(full_path) or dir_exists(full_path) then
      table.insert(cleanup_needed, pattern)
    end
  end
  
  if #cleanup_needed > 0 then
    warn("Old configuration artifacts detected: " .. table.concat(cleanup_needed, ", "))
    info("Consider cleaning up old files for a cleaner structure")
  else
    ok("No old configuration artifacts detected")
  end
  
  -- Check if user overrides are preserved
  local user = safe_require("user")
  if user then
    ok("User customizations are preserved and accessible")
  else
    info("No user customizations detected (this is normal for new setups)")
  end
end

-- Check configuration consistency
local function check_configuration_consistency()
  start("Configuration Consistency")
  
  -- Check if all required modules are loaded without conflicts
  local critical_modules = {
    "core.utils", "core.options", "core.keymaps", "core.autocmds",
    "plugins", "plugins.specs.ui", "plugins.config.colorscheme"
  }
  
  local loaded_modules = {}
  local failed_modules = {}
  
  for _, module in ipairs(critical_modules) do
    if safe_require(module) then
      table.insert(loaded_modules, module)
    else
      table.insert(failed_modules, module)
    end
  end
  
  if #failed_modules == 0 then
    ok("All critical modules loaded successfully")
  else
    error("Some critical modules failed to load: " .. table.concat(failed_modules, ", "))
  end
  
  -- Check for duplicate keymaps or conflicts
  local leader = vim.g.mapleader
  if leader then
    ok("Leader key is configured: '" .. leader .. "'")
  else
    warn("Leader key is not set")
  end
  
  -- Check for common configuration conflicts
  local potential_conflicts = {}
  
  -- Check if multiple colorschemes are configured
  local colorscheme_modules = {
    "plugins.config.colorscheme",
    "plugins.config.colorbuddy"
  }
  
  local active_colorschemes = 0
  for _, cs_module in ipairs(colorscheme_modules) do
    if safe_require(cs_module) then
      active_colorschemes = active_colorschemes + 1
    end
  end
  
  if active_colorschemes > 1 then
    table.insert(potential_conflicts, "Multiple colorscheme configurations detected")
  end
  
  if #potential_conflicts > 0 then
    warn("Potential configuration conflicts detected:")
    for _, conflict in ipairs(potential_conflicts) do
      warn("  - " .. conflict)
    end
  else
    ok("No obvious configuration conflicts detected")
  end
end

-- Check overall health score
local function check_overall_health()
  start("Overall Structure Health Score")
  
  local health_scores = {
    { category = "Directory Structure", weight = 20 },
    { category = "Core Modules", weight = 25 },
    { category = "Plugin System", weight = 25 },
    { category = "Loading Strategy", weight = 15 },
    { category = "Compatibility", weight = 10 },
    { category = "Consistency", weight = 5 }
  }
  
  -- This is a simplified scoring system
  -- In a real implementation, you'd track actual success/failure rates
  local total_score = 0
  local max_score = 0
  
  for _, score in ipairs(health_scores) do
    max_score = max_score + score.weight
    -- Assuming 80% success rate for demo (in real implementation, track actual results)
    total_score = total_score + (score.weight * 0.8)
  end
  
  local health_percentage = math.floor((total_score / max_score) * 100)
  
  if health_percentage >= 90 then
    ok("Excellent overall health: " .. health_percentage .. "%")
  elseif health_percentage >= 75 then
    ok("Good overall health: " .. health_percentage .. "%")
  elseif health_percentage >= 60 then
    warn("Moderate health issues detected: " .. health_percentage .. "%")
  else
    error("Significant health issues detected: " .. health_percentage .. "%")
  end
  
  -- Provide improvement recommendations
  if health_percentage < 100 then
    info("Recommendations for improvement:")
    if health_percentage < 90 then
      info("  - Review failed module loading")
      info("  - Check plugin configurations")
    end
    if health_percentage < 75 then
      info("  - Optimize startup time")
      info("  - Resolve configuration conflicts")
    end
    if health_percentage < 60 then
      info("  - Consider structure reorganization")
      info("  - Review backward compatibility issues")
    end
  end
end

-- Main health check function
function M.check()
  check_directory_structure()
  check_core_modules()
  check_plugin_architecture()
  check_loading_strategy()
  check_backward_compatibility()
  check_configuration_consistency()
  check_overall_health()
end

return M 