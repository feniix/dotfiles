-- Health check module for Neovim configuration
local M = {}

-- Define health check module
local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

-- Check if plugin exists in any of the possible locations
local function has_plugin(plugin_name)
  -- Check in lazy.nvim paths
  local lazy_path = vim.fn.stdpath("data") .. "/lazy/" .. plugin_name
  
  if vim.fn.isdirectory(lazy_path) == 1 then
    return true, "lazy.nvim"
  end
  
  return false, nil
end

-- Check if executable exists in path
local function has_executable(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Check installer module and tool availability
local function check_installer()
  start("Tool Installation System")
  
  -- Check if installer module is available
  local installer_ok, installer = pcall(require, "core.installer")
  if installer_ok then
    ok("Installer module is loaded correctly")
    
    -- Show available commands
    info("Available commands: :InstallSystemTools, :InstallGoTools, :InstallNodeTools, :InstallPythonTools, :InstallAllTools")
    
    -- Check system tools
    local system_tools = { "ripgrep", "fd", "fzf" }
    local missing_system = {}
    
    for _, tool in ipairs(system_tools) do
      if has_executable(tool) or has_executable(tool:gsub("ripgrep", "rg")) then
        ok(tool .. " is installed")
      else
        table.insert(missing_system, tool)
        warn(tool .. " is not installed")
      end
    end
    
    if #missing_system > 0 then
      info("Run :InstallSystemTools to install missing tools")
      info("Or manually: :lua require('core.installer').install_system_tools()")
    else
      ok("All system tools are installed")
    end
    
    -- Check language tools
    local languages = { "go", "node", "python" }
    
    for _, lang in ipairs(languages) do
      if has_executable(lang) then
        ok(lang .. " runtime is available")
        
        -- Get available tools for this language
        local tools = installer.get_available_tools(lang)
        if #tools > 0 then
          local missing_tools = {}
          for _, tool in ipairs(tools) do
            if installer.is_tool_installed(tool) then
              ok(lang .. " tool: " .. tool .. " is installed")
            else
              table.insert(missing_tools, tool)
              warn(lang .. " tool: " .. tool .. " is missing")
            end
          end
          
          if #missing_tools > 0 then
            info("Run :Install" .. lang:gsub("^%l", string.upper) .. "Tools to install missing " .. lang .. " tools")
            info("Or manually: :lua require('core.installer').install_language_tools('" .. lang .. "')")
          else
            ok("All " .. lang .. " tools are installed")
          end
        else
          info("No additional tools defined for " .. lang)
        end
      else
        warn(lang .. " runtime not found")
        info("Install " .. lang .. " via asdf: asdf install " .. lang .. " latest")
      end
    end
    
    -- Check rust separately (has minimal tools)
    if has_executable("rustc") then
      ok("rust runtime is available")
      if has_executable("rust-analyzer") then
        ok("rust-analyzer is installed")
      else
        warn("rust-analyzer is missing")
        info("Install via asdf: asdf install rust-analyzer latest")
      end
    else
      warn("rust runtime not found")
      info("Install rust via asdf: asdf install rust latest")
    end
    
    -- Check asdf itself
    if has_executable("asdf") then
      ok("asdf version manager is available")
      local asdf_version = vim.fn.trim(vim.fn.system("asdf --version"))
      info("asdf version: " .. asdf_version)
    else
      warn("asdf version manager not found")
      info("Install asdf: https://asdf-vm.com/guide/getting-started.html")
    end
    
  else
    error("Installer module could not be loaded: " .. tostring(installer))
    info("Check that lua/core/installer.lua exists and is valid")
  end
end

-- Check debugger configuration
local function check_dap()
  start("Debugging Configuration")
  
  -- Check DAP module
  local dap_ok, _ = pcall(require, "dap")
  if dap_ok then
    ok("DAP module is loaded correctly")
  else
    error("DAP module could not be loaded")
  end
  
  -- Check DAP UI
  local has_dapui, dapui_location = has_plugin("nvim-dap-ui")
  if has_dapui then
    local dapui_ok, _ = pcall(require, "dapui")
    if dapui_ok then
      ok("nvim-dap-ui is installed via " .. dapui_location .. " and loaded correctly")
    else
      warn("nvim-dap-ui is installed but cannot be loaded")
    end
  else
    warn("nvim-dap-ui is missing, install with :Lazy sync")
  end
  
  -- Check nvim-nio dependency
  local has_nio, nio_location = has_plugin("nvim-nio")
  if has_nio then
    ok("nvim-nio is installed via " .. nio_location .. " (required by nvim-dap-ui)")
  else
    error("nvim-nio is missing, but is required by nvim-dap-ui. Install with :Lazy sync")
  end
  
  -- Check virtual text 
  local has_vt, vt_location = has_plugin("nvim-dap-virtual-text")
  if has_vt then
    local vt_ok, _ = pcall(require, "nvim-dap-virtual-text")
    if vt_ok then
      ok("nvim-dap-virtual-text is installed via " .. vt_location .. " and loaded correctly")
    else
      warn("nvim-dap-virtual-text is installed but cannot be loaded")
    end
  else
    info("nvim-dap-virtual-text is missing, install for enhanced debugging experience")
  end
  
  -- Check language-specific debugger support
  -- Go - delve
  if has_executable("dlv") then
    ok("dlv (Delve) debugger for Go is installed")
  else
    warn("dlv debugger is not found in PATH. Go debugging may not work correctly")
  end
end

-- Check Go configuration
local function check_go()
  start("Go Development Environment")
  
  -- Check vim-go
  local has_vimgo, vimgo_location = has_plugin("vim-go")
  if has_vimgo then
    ok("vim-go is installed via " .. vimgo_location)
  else
    error("vim-go is missing. Install with :Lazy sync")
  end
  
  -- Check Go tools using platform module if available
  local platform = _G.platform
  if platform then
    local tools = platform.get_language_tools()
    if tools.go then
      if has_executable("go") then
        ok("Go is installed and in PATH")
        
        -- Check Go version
        local go_version = vim.fn.trim(vim.fn.system("go version"))
        info("Go version: " .. go_version)
        
        -- Check essential Go tools using platform detection
        local go_tools = {
          { name = "goimports", available = tools.go.goimports },
          { name = "gofumpt", available = tools.go.gofumpt },
          { name = "golangci-lint", available = tools.go.golangci_lint },
          { name = "gomodifytags", available = tools.go.gomodifytags },
          { name = "gotests", available = tools.go.gotests },
          { name = "dlv", available = tools.go.dlv },
        }
        
        for _, tool in ipairs(go_tools) do
          if tool.available then
            ok(tool.name .. " is installed")
          else
            warn(tool.name .. " is not found in PATH")
          end
        end
        
        -- Additional tools that aren't in platform module yet
        local extra_tools = { "impl", "gorename" }
        for _, tool in ipairs(extra_tools) do
          if has_executable(tool) then
            ok(tool .. " is installed")
          else
            warn(tool .. " is not found in PATH")
          end
        end
      else
        error("Go is not installed or not in PATH")
      end
    end
  else
    -- Fallback to original behavior if platform module isn't available
    if has_executable("go") then
      ok("Go is installed and in PATH")
      
      -- Check Go version
      local go_version = vim.fn.trim(vim.fn.system("go version"))
      info("Go version: " .. go_version)
      
      -- Check essential Go tools
      local go_tools = {
        "goimports", "gofumpt", "golangci-lint", "gomodifytags",
        "gotests", "impl", "dlv", "gorename"
      }
      
      for _, tool in ipairs(go_tools) do
        if has_executable(tool) then
          ok(tool .. " is installed")
        else
          warn(tool .. " is not found in PATH")
        end
      end
    else
      error("Go is not installed or not in PATH")
    end
  end
end

-- Check platform detection module
local function check_platform()
  start("Platform Detection")
  
  -- Check if platform module is available
  local utils_ok, utils = pcall(require, 'core.utils')
  if utils_ok and utils.platform then
    local platform = utils.platform
    ok("Platform detection module is loaded")
    
    -- Show platform information
    local os_name = platform.get_os()
    local terminal = platform.get_terminal()
    local is_gui = platform.is_gui()
    local arch = platform.get_arch()
    local pm = platform.get_package_manager()
    
    info("Operating System: " .. os_name)
    info("Architecture: " .. arch)
    info("Package Manager: " .. pm)
    info("Terminal: " .. terminal)
    info("GUI Environment: " .. (is_gui and "Yes" or "No"))
    
    -- Check platform-specific recommendations
    if os_name == "macos" and arch ~= "arm64" then
      warn("Intel Mac detected - this configuration is optimized for Apple Silicon")
      info("Consider using ARM64 macOS or x86_64 Linux instead")
    elseif os_name == "linux" and arch ~= "x86_64" then
      warn("Non-x86_64 Linux detected - this configuration is optimized for x86_64")
    else
      ok("Platform is supported: " .. os_name .. " " .. arch)
    end
    
    -- Check clipboard configuration
    local clipboard_config = platform.get_clipboard_config()
    if clipboard_config and next(clipboard_config) ~= nil then
      ok("Clipboard is configured for " .. clipboard_config.name)
      
      -- Check if clipboard utilities are available
      if os_name == "linux" or os_name == "freebsd" or os_name == "openbsd" then
        if vim.fn.executable('wl-copy') == 1 and vim.fn.executable('wl-paste') == 1 then
          ok("Wayland clipboard utilities (wl-copy/wl-paste) are available")
        elseif vim.fn.executable('xclip') == 1 then
          ok("X11 clipboard utility (xclip) is available")
        elseif vim.fn.executable('xsel') == 1 then
          ok("X11 clipboard utility (xsel) is available")
        else
          warn("No clipboard utilities found")
          if pm == "homebrew" then
            info("Install with: brew install wl-clipboard")
          elseif pm == "apt" then
            info("Install with: sudo apt install wl-clipboard xclip")
          elseif pm == "dnf" then
            info("Install with: sudo dnf install wl-clipboard xclip")
          elseif pm == "pacman" then
            info("Install with: sudo pacman -S wl-clipboard xclip")
          end
        end

      elseif os_name == "macos" then
        if vim.fn.executable('pbcopy') == 1 and vim.fn.executable('pbpaste') == 1 then
          ok("macOS clipboard utilities (pbcopy/pbpaste) are available")
        else
          error("macOS clipboard utilities are missing")
        end
      end
    else
      warn("No clipboard configuration detected")
    end
    
    -- Check terminal capabilities
    local caps = platform.get_capabilities()
    if caps.true_color then
      ok("Terminal supports true color")
    else
      warn("Terminal may not support true color")
      info("Set COLORTERM=truecolor or use a modern terminal")
    end
    
    if caps.mouse then
      ok("Terminal supports mouse")
    else
      warn("Terminal may not support mouse")
    end
    
    if caps.undercurl then
      ok("Terminal supports undercurl")
    else
      info("Terminal does not support undercurl (cosmetic only)")
    end
    
    if caps.clipboard then
      ok("Clipboard integration is available")
    else
      warn("Clipboard integration may not work properly")
    end
    
    -- Check platform-specific plugin configurations
    local platform_config_ok, _ = pcall(require, 'plugins.config.platform')
    if platform_config_ok then
      ok("Platform-specific plugin configurations are available")
    else
      warn("Platform-specific plugin configurations not found")
    end
    
  else
    error("Platform detection module could not be loaded")
    
    -- Show basic fallback information
    if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
      info("Operating System: macOS (fallback detection)")
    elseif vim.fn.has("unix") == 1 then
      info("Operating System: Unix/Linux (fallback detection)")
    else
      info("Operating System: Unknown")
    end
  end
end

-- Check treesitter setup
local function check_treesitter()
  start("Treesitter Configuration")
  
  local has_ts, ts_location = has_plugin("nvim-treesitter")
  if has_ts then
    local ts_ok, _ = pcall(require, "nvim-treesitter")
    if ts_ok then
      ok("nvim-treesitter is installed via " .. ts_location .. " and loaded correctly")
    else
      error("nvim-treesitter is installed but cannot be loaded")
    end
  else
    error("nvim-treesitter is missing, install with :Lazy sync")
  end
  
  -- Check TreeSitter module
  local user_ts_ok, _ = pcall(require, "plugins.config.treesitter")
  if user_ts_ok then
    ok("Treesitter module is loaded correctly")
  else
    error("Treesitter module could not be loaded")
  end
  
  -- Check some basic treesitter parsers
  local parsers_to_check = {
    "lua", "vim", "go", "json", "markdown"
  }
  
  -- Use pcall to protect against any treesitter errors
  local parser_installed = function(lang)
    local parser_ok, parsers = pcall(require, "nvim-treesitter.parsers")
    if not parser_ok then return false end
    
    -- Prefer using the newer treesitter API if available
    if parsers.has_parser then
      return parsers.has_parser(lang)
    else
      -- Fallback to older method
      local config_ok, _ = pcall(require, "nvim-treesitter.configs")
      if not config_ok then return false end
      
      return vim.fn.executable(
        vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser/" .. 
        lang .. ".so"
      ) == 1
    end
  end
  
  for _, lang in ipairs(parsers_to_check) do
    if parser_installed(lang) then
      ok(lang .. " parser is installed")
    else
      warn(lang .. " parser is not installed")
    end
  end
end

-- Check completion plugin configuration
local function check_completion()
  start("Completion Engine Configuration")
  
  -- Check nvim-cmp
  local has_cmp, cmp_location = has_plugin("nvim-cmp")
  if has_cmp then
    local cmp_ok, _ = pcall(require, "cmp")
    if cmp_ok then
      ok("nvim-cmp is installed via " .. cmp_location .. " and loaded correctly")
    else
      error("nvim-cmp is installed but cannot be loaded")
    end
  else
    error("nvim-cmp is missing, install with :Lazy sync")
  end
  
  -- Check common sources
  local required_sources = {
    "cmp-buffer", "cmp-path", "cmp-cmdline"
  }
  
  for _, source in ipairs(required_sources) do
    local has_source, source_location = has_plugin(source)
    if has_source then
      ok(source .. " is installed via " .. source_location)
    else
      warn(source .. " is missing, install with :Lazy sync for better completion")
    end
  end
end

-- Check plugin platform compatibility
local function check_plugin_compatibility()
  start("Plugin Platform Compatibility")
  
  -- Check platform-aware plugin override system
  local platform_override_ok, platform_override = pcall(require, 'user.overrides.plugins.platform')
  if platform_override_ok then
    ok("Platform-aware plugin override system is available")
    
    -- Test platform conditions
    local conditions = platform_override.get_platform_conditions()
    local utils = require('core.utils')
    
    -- Check git-dependent plugins
    if conditions.git_required() then
      ok("Git-dependent plugins will load (git is available)")
    else
      warn("Git-dependent plugins will be disabled (git not found)")
      info("Install git via package manager or asdf")
    end
    
    -- Check build tools for native extensions
    if conditions.build_tools_required() then
      ok("Build tools available for native plugin extensions")
    else
      warn("Build tools missing - some plugins may not compile")
      local pm = utils.platform.get_package_manager()
      if pm == "homebrew" then
        info("Install with: xcode-select --install")
      elseif pm == "apt" then
        info("Install with: sudo apt install build-essential cmake")
      elseif pm == "dnf" then
        info("Install with: sudo dnf groupinstall 'Development Tools' && sudo dnf install cmake")
      elseif pm == "pacman" then
        info("Install with: sudo pacman -S base-devel cmake")
      end
    end
    
    -- Check terminal capabilities for UI plugins
    if conditions.true_color_required() then
      ok("True color support available for colorschemes")
    else
      warn("True color support missing - colorschemes may look incorrect")
      info("Use a modern terminal or set COLORTERM=truecolor")
    end
    
    if conditions.clipboard_required() then
      ok("Clipboard integration available")
    else
      warn("Clipboard integration may not work")
      info("Install clipboard utilities for your platform")
    end
    
    -- Platform-specific recommendations
    if utils.platform.is_mac() then
      info("macOS detected - using Cmd key bindings")
      if utils.platform.is_iterm2() then
        ok("iTerm2 detected - enhanced terminal features available")
      else
        info("Consider using iTerm2 for better terminal integration")
      end
    else
      info("Linux detected - using Ctrl key bindings")
      if vim.env.WAYLAND_DISPLAY then
        info("Wayland detected - ensure wl-clipboard is installed")
      elseif vim.env.DISPLAY then
        info("X11 detected - ensure xclip or xsel is installed")
      end
    end
    
  else
    warn("Platform-aware plugin override system not found")
    info("Some plugins may not be optimized for your platform")
  end
  
  -- Check specific plugin configurations
  local telescope_override_ok, _ = pcall(require, 'user.overrides.plugins.telescope')
  if telescope_override_ok then
    ok("Telescope platform overrides are available")
  else
    warn("Telescope platform overrides not found")
  end
  
  local platform_config_ok, _ = pcall(require, 'plugins.config.platform')
  if platform_config_ok then
    ok("Platform-specific plugin configurations are available")
  else
    warn("Platform-specific plugin configurations not found")
  end
end

-- Register the health check with Neovim's built-in health check system
function M.check()
  check_platform()
  check_installer()
  check_plugin_compatibility()
  check_dap()
  check_go()
  check_treesitter()
  check_completion()
end

-- Setup function that creates user command and hooks into Neovim's health check
function M.setup()
  -- Create a user command for direct access
  vim.api.nvim_create_user_command('UserConfig', function()
    vim.cmd('checkhealth user')
  end, { desc = 'Check your Neovim configuration health' })
end

return M 