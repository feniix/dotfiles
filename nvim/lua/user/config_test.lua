-- Configuration testing module
-- Provides utilities to test Neovim configuration without crashing
local M = {}

-- Test if a Lua module can be loaded successfully
-- Returns true if successful, false otherwise
function M.test_module(module_name)
  local ok, result = pcall(require, module_name)
  if not ok then
    vim.notify("Failed to load module: " .. module_name .. "\nError: " .. tostring(result), vim.log.levels.ERROR)
    return false
  end
  vim.notify("Successfully loaded module: " .. module_name, vim.log.levels.INFO)
  return true
end

-- Test all core modules to ensure they load properly
function M.test_all_core_modules()
  local modules = {
    "user.treesitter"
  }
  
  local results = {}
  for _, module in ipairs(modules) do
    results[module] = M.test_module(module)
  end
  
  -- Print summary
  vim.notify("==== Module Test Results ====", vim.log.levels.INFO)
  local all_passed = true
  for module, success in pairs(results) do
    local status = success and "OK" or "FAILED"
    vim.notify(string.format("Module %-25s: %s", module, status), 
               success and vim.log.levels.INFO or vim.log.levels.ERROR)
    if not success then all_passed = false end
  end
  
  return all_passed
end

-- Check for plugin availability
function M.test_plugins()
  local plugins = {
    {"nvim-treesitter", "TreeSitter"},
    {"nvim-cmp", "Completion engine"}
  }
  
  local results = {}
  for _, plugin in ipairs(plugins) do
    local name, desc = unpack(plugin)
    local success = pcall(require, name)
    
    results[desc] = success
  end
  
  -- Print summary
  vim.notify("==== Plugin Availability ====", vim.log.levels.INFO)
  local all_present = true
  for desc, available in pairs(results) do
    local status = available and "Available" or "Missing"
    vim.notify(string.format("%-25s: %s", desc, status), 
               available and vim.log.levels.INFO or vim.log.levels.WARN)
    if not available then all_present = false end
  end
  
  return all_present
end

-- Test global variables setup
function M.test_globals()
  local globals = {
    {"skip_telescope", "Telescope disabled"},
    {"skip_treesitter_setup", "TreeSitter setup disabled"},
    {"skip_plugin_installer", "Plugin installer disabled"}
  }
  
  vim.notify("==== Global Settings ====", vim.log.levels.INFO)
  for _, global in ipairs(globals) do
    local name, desc = unpack(global)
    local full_name = "vim.g." .. name
    local value = vim.g[name]
    local status = value and "true" or "false"
    
    vim.notify(string.format("%-30s: %s (%s)", desc, status, value == true), 
               vim.log.levels.INFO)
  end
end

-- Test for inconsistencies between plugins and settings
function M.test_plugin_setting_consistency()
  vim.notify("==== Plugin/Settings Consistency Check ====", vim.log.levels.INFO)
  
  -- Define plugin-setting relationships to check
  local checks = {
    {
      plugins = {"rust-analyzer", "rust.vim", "rust-lang/rust.vim"},
      settings = {"rustfmt_autosave", "racer_experimental_completer"},
      name = "Rust"
    },
    {
      plugins = {"elixir-editors/vim-elixir", "elixir-lang/vim-elixir", "elixir"},
      settings = {"mix_format_on_save"},
      name = "Elixir"
    },
    {
      plugins = {"rodjek/vim-puppet"},
      settings = {},
      name = "Puppet"
    }
  }
  
  -- Check each relationship
  local inconsistencies = {}
  
  for _, check in ipairs(checks) do
    local plugin_exists = false
    
    -- Check if any of the related plugins exists
    for _, plugin in ipairs(check.plugins) do
      -- Check in runtimepath for the plugin
      if vim.fn.finddir(plugin, vim.o.runtimepath) ~= "" or 
         vim.fn.finddir("*" .. plugin .. "*", vim.o.runtimepath) ~= "" then
        plugin_exists = true
        break
      end
    end
    
    -- Check if any of the settings exists
    local settings_exist = false
    for _, setting in ipairs(check.settings) do
      if vim.fn.exists('g:' .. setting) == 1 then
        settings_exist = true
        break
      end
    end
    
    -- Record inconsistency
    if settings_exist and not plugin_exists then
      table.insert(inconsistencies, {
        name = check.name,
        issue = "Settings found but no corresponding plugins installed"
      })
    end
  end
  
  -- Report findings
  if #inconsistencies == 0 then
    vim.notify("No plugin/setting inconsistencies found", vim.log.levels.INFO)
  else
    vim.notify("Found " .. #inconsistencies .. " potential inconsistencies:", vim.log.levels.WARN)
    for _, issue in ipairs(inconsistencies) do
      vim.notify(issue.name .. ": " .. issue.issue, vim.log.levels.WARN)
    end
  end
  
  return #inconsistencies == 0
end

-- Create command to run all tests
function M.create_commands()
  vim.api.nvim_create_user_command('TestConfig', function()
    vim.notify("Starting Neovim configuration tests...", vim.log.levels.INFO)
    
    local modules_ok = M.test_all_core_modules()
    local plugins_ok = M.test_plugins()
    M.test_globals()
    local consistency_ok = M.test_plugin_setting_consistency()
    
    vim.notify("==== Test Summary ====", vim.log.levels.INFO)
    vim.notify("Core modules: " .. (modules_ok and "All OK" or "Some failed"), 
               modules_ok and vim.log.levels.INFO or vim.log.levels.ERROR)
    vim.notify("Required plugins: " .. (plugins_ok and "All available" or "Some missing"), 
               plugins_ok and vim.log.levels.INFO or vim.log.levels.WARN)
    vim.notify("Plugin/Settings consistency: " .. (consistency_ok and "OK" or "Issues found"),
               consistency_ok and vim.log.levels.INFO or vim.log.levels.WARN)
    
    if not modules_ok or not plugins_ok or not consistency_ok then
      vim.notify("Some tests failed. Check the logs for details.", vim.log.levels.WARN)
    else
      vim.notify("All tests passed! Your configuration looks good.", vim.log.levels.INFO)
    end
  end, { desc = "Test Neovim configuration" })
  
  vim.api.nvim_create_user_command('TestModule', function(opts)
    if opts.args and opts.args ~= "" then
      M.test_module(opts.args)
    else
      vim.notify("Please specify a module name", vim.log.levels.ERROR)
    end
  end, { nargs = 1, desc = "Test a specific Neovim module", complete = function()
    return {"user.treesitter"}
  end})
end

return M 