-- Health check module for plugin system
-- This module validates the integrity of the plugin management and configuration

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

-- Check if plugin exists in lazy.nvim
local function has_plugin(plugin_name)
  local lazy_path = vim.fn.stdpath("data") .. "/lazy/" .. plugin_name
  return vim.fn.isdirectory(lazy_path) == 1
end

-- Check if executable exists in PATH
local function has_executable(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Check plugin manager (lazy.nvim)
local function check_plugin_manager()
  start("Plugin Manager (lazy.nvim)")
  
  -- Check if lazy.nvim is installed
  if not has_plugin("lazy.nvim") then
    error("lazy.nvim is not installed")
    return
  end
  
  ok("lazy.nvim is installed")
  
  -- Check if lazy module can be loaded
  local lazy = safe_require("lazy")
  if not lazy then
    error("lazy.nvim module could not be loaded")
    return
  end
  
  ok("lazy.nvim module is loaded successfully")
  
  -- Check plugins init module
  local plugins_init = safe_require("plugins")
  if not plugins_init then
    error("plugins module could not be loaded")
    return
  end
  
  ok("plugins module is loaded successfully")
  
  -- Check if setup function exists
  if plugins_init.setup and type(plugins_init.setup) == "function" then
    ok("plugins.setup function is available")
  else
    warn("plugins.setup function is missing")
  end
  
  -- Get plugin stats if available
  if lazy.stats then
    local stats = lazy.stats()
    if stats then
      info("Total plugins: " .. (stats.count or "unknown"))
      info("Loaded plugins: " .. (stats.loaded or "unknown"))
      if stats.startuptime then
        info("Startup time: " .. string.format("%.2f", stats.startuptime) .. "ms")
      end
    end
  end
end

-- Check plugin specifications
local function check_plugin_specs()
  start("Plugin Specifications")
  
  local spec_modules = {
    "plugins.specs.ui",
    "plugins.specs.editor", 
    "plugins.specs.lsp",
    "plugins.specs.tools"
  }
  
  for _, spec_module in ipairs(spec_modules) do
    local module = safe_require(spec_module)
    if module then
      ok("Plugin spec '" .. spec_module .. "' is loaded")
      
      -- Check if it returns a table (plugin spec format)
      if type(module) == "table" then
        ok("Plugin spec '" .. spec_module .. "' has valid format")
        
        -- Count plugins in spec
        local plugin_count = 0
        for _, spec in ipairs(module) do
          if type(spec) == "table" or type(spec) == "string" then
            plugin_count = plugin_count + 1
          end
        end
        
        if plugin_count > 0 then
          info("Plugin spec '" .. spec_module .. "' defines " .. plugin_count .. " plugins")
        end
      else
        warn("Plugin spec '" .. spec_module .. "' does not return a valid table")
      end
    else
      warn("Plugin spec '" .. spec_module .. "' could not be loaded")
    end
  end
  
  -- Check language-specific specs
  local lang_specs = {
    "plugins.specs.lang.go",
    "plugins.specs.lang.terraform", 
    "plugins.specs.lang.puppet"
  }
  
  for _, lang_spec in ipairs(lang_specs) do
    local module = safe_require(lang_spec)
    if module then
      ok("Language spec '" .. lang_spec .. "' is loaded")
    else
      info("Language spec '" .. lang_spec .. "' is not available (may be optional)")
    end
  end
end

-- Check essential plugin configurations
local function check_essential_configs()
  start("Essential Plugin Configurations")
  
  local essential_configs = {
    { name = "colorscheme", module = "plugins.config.colorscheme", critical = true },
    { name = "telescope", module = "plugins.config.telescope", critical = true },
    { name = "treesitter", module = "plugins.config.treesitter", critical = true },
    { name = "cmp", module = "plugins.config.cmp", critical = true },
    { name = "lualine", module = "plugins.config.lualine", critical = false },
    { name = "gitsigns", module = "plugins.config.gitsigns", critical = false },
    { name = "which-key", module = "plugins.config.which-key", critical = false },
  }
  
  for _, config in ipairs(essential_configs) do
    local module = safe_require(config.module)
    if module then
      ok("Configuration '" .. config.name .. "' is loaded")
      
      -- Check if setup function exists
      if module.setup and type(module.setup) == "function" then
        ok("Configuration '" .. config.name .. "' has setup function")
      else
        if config.critical then
          warn("Configuration '" .. config.name .. "' is missing setup function")
        else
          info("Configuration '" .. config.name .. "' may not require setup function")
        end
      end
    else
      if config.critical then
        error("Critical configuration '" .. config.name .. "' could not be loaded")
      else
        info("Optional configuration '" .. config.name .. "' is not available")
      end
    end
  end
end

-- Check advanced plugin configurations
local function check_advanced_configs()
  start("Advanced Plugin Configurations")
  
  local advanced_configs = {
    { name = "dap", module = "plugins.config.dap", deps = {"nvim-dap", "nvim-dap-ui"} },
    { name = "diffview", module = "plugins.config.diffview", deps = {"diffview.nvim"} },
    { name = "indent-blankline", module = "plugins.config.indent-blankline", deps = {"indent-blankline.nvim"} },
  }
  
  for _, config in ipairs(advanced_configs) do
    local module = safe_require(config.module)
    if module then
      ok("Advanced configuration '" .. config.name .. "' is loaded")
      
      -- Check plugin dependencies
      local all_deps_available = true
      for _, dep in ipairs(config.deps or {}) do
        if not has_plugin(dep) then
          all_deps_available = false
          warn("Dependency '" .. dep .. "' for '" .. config.name .. "' is not installed")
        end
      end
      
      if all_deps_available then
        ok("All dependencies for '" .. config.name .. "' are available")
      end
    else
      info("Advanced configuration '" .. config.name .. "' is not available")
    end
  end
end

-- Check language-specific configurations
local function check_language_configs()
  start("Language-Specific Configurations")
  
  local language_configs = {
    { name = "Go", module = "plugins.config.lang.go", executables = {"go", "goimports", "gofumpt"} },
    { name = "Terraform", module = "plugins.config.lang.terraform", executables = {"terraform"} },
    { name = "Puppet", module = "plugins.config.lang.puppet", executables = {"puppet"} },
  }
  
  for _, lang in ipairs(language_configs) do
    local module = safe_require(lang.module)
    if module then
      ok("Language configuration for " .. lang.name .. " is loaded")
      
      -- Check executables
      local available_executables = 0
      for _, exec in ipairs(lang.executables or {}) do
        if has_executable(exec) then
          available_executables = available_executables + 1
          ok(lang.name .. " executable '" .. exec .. "' is available")
        else
          warn(lang.name .. " executable '" .. exec .. "' is not found in PATH")
        end
      end
      
      if available_executables == #(lang.executables or {}) then
        ok("All " .. lang.name .. " tools are available")
      elseif available_executables > 0 then
        warn("Some " .. lang.name .. " tools are missing")
      else
        error("No " .. lang.name .. " tools found")
      end
    else
      info("Language configuration for " .. lang.name .. " is not available")
    end
  end
end

-- Check plugin health
local function check_plugin_health()
  start("Individual Plugin Health")
  
  -- Check telescope
  local telescope = safe_require("telescope")
  if telescope then
    ok("Telescope is loaded")
    
    -- Check if builtin is available
    local builtin = safe_require("telescope.builtin")
    if builtin then
      ok("Telescope builtin functions are available")
    else
      warn("Telescope builtin functions are not available")
    end
    
    -- Check extensions
    local extensions = {"fzf"}
    for _, ext in ipairs(extensions) do
      local ext_loaded = pcall(telescope.load_extension, ext)
      if ext_loaded then
        ok("Telescope extension '" .. ext .. "' is loaded")
      else
        warn("Telescope extension '" .. ext .. "' could not be loaded")
      end
    end
  else
    warn("Telescope is not available")
  end
  
  -- Check treesitter
  local ts = safe_require("nvim-treesitter")
  if ts then
    ok("TreeSitter is loaded")
    
    -- Check parsers
    local parsers = safe_require("nvim-treesitter.parsers")
    if parsers then
      local installed_parsers = {}
      for lang, _ in pairs(parsers.get_parser_configs()) do
        if parsers.has_parser(lang) then
          table.insert(installed_parsers, lang)
        end
      end
      
      if #installed_parsers > 0 then
        ok("TreeSitter has " .. #installed_parsers .. " parsers installed")
        info("Sample parsers: " .. table.concat(vim.list_slice(installed_parsers, 1, 5), ", "))
      else
        warn("No TreeSitter parsers are installed")
      end
    end
  else
    warn("TreeSitter is not available")
  end
  
  -- Check completion
  local cmp = safe_require("cmp")
  if cmp then
    ok("nvim-cmp is loaded")
    
    -- Check if completion is configured
    if cmp.get_config then
      local config = cmp.get_config()
      if config and config.sources then
        ok("Completion sources are configured")
        info("Number of completion sources: " .. #config.sources)
      else
        warn("Completion sources are not configured")
      end
    end
  else
    warn("nvim-cmp is not available")
  end
end

-- Check performance
local function check_performance()
  start("Plugin Performance")
  
  local lazy = safe_require("lazy")
  if lazy and lazy.stats then
    local stats = lazy.stats()
    
    if stats.startuptime then
      local startup_time = stats.startuptime
      if startup_time < 50 then
        ok("Excellent startup time: " .. string.format("%.2f", startup_time) .. "ms")
      elseif startup_time < 100 then
        ok("Good startup time: " .. string.format("%.2f", startup_time) .. "ms")
      elseif startup_time < 200 then
        warn("Moderate startup time: " .. string.format("%.2f", startup_time) .. "ms")
      else
        warn("Slow startup time: " .. string.format("%.2f", startup_time) .. "ms")
      end
    end
    
    if stats.loaded and stats.count then
      local lazy_loaded = stats.count - stats.loaded
      if lazy_loaded > 0 then
        ok(lazy_loaded .. " plugins are lazy-loaded (performance optimized)")
      else
        info("All plugins are loaded at startup")
      end
    end
  else
    info("Performance statistics are not available")
  end
  
  -- Check memory usage
  local mem_usage = collectgarbage("count")
  if mem_usage < 50000 then  -- 50MB
    ok("Memory usage is reasonable: " .. string.format("%.2f", mem_usage / 1024) .. "MB")
  elseif mem_usage < 100000 then  -- 100MB
    warn("Memory usage is moderate: " .. string.format("%.2f", mem_usage / 1024) .. "MB")
  else
    warn("Memory usage is high: " .. string.format("%.2f", mem_usage / 1024) .. "MB")
  end
end

-- Main health check function
function M.check()
  check_plugin_manager()
  check_plugin_specs()
  check_essential_configs()
  check_advanced_configs() 
  check_language_configs()
  check_plugin_health()
  check_performance()
end

return M 