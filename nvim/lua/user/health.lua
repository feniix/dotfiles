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
  local platform = _G.platform
  if platform then
    ok("Platform detection module is loaded")
    
    -- Show platform information
    local os_name = platform.get_os()
    local terminal = platform.get_terminal()
    local is_gui = platform.is_gui()
    
    info("Operating System: " .. os_name)
    info("Terminal: " .. terminal)
    info("GUI Environment: " .. (is_gui and "Yes" or "No"))
    
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
          warn("No clipboard utilities found. Install wl-clipboard (Wayland) or xclip/xsel (X11)")
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
    local terminal_config = platform.get_terminal_config()
    if terminal_config.supports_true_color then
      ok("Terminal supports true color")
    else
      warn("Terminal may not support true color")
    end
    
    if terminal_config.supports_mouse then
      ok("Terminal supports mouse")
    else
      warn("Terminal may not support mouse")
    end
    
    if terminal_config.supports_undercurl then
      ok("Terminal supports undercurl")
    else
      info("Terminal does not support undercurl (cosmetic only)")
    end
    
    -- Check platform-specific keymaps
    local keymaps = platform.get_platform_keymaps()
    if #keymaps > 0 then
      ok(#keymaps .. " platform-specific keymaps are configured")
    else
      info("No platform-specific keymaps configured")
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
    local ok, parsers = pcall(require, "nvim-treesitter.parsers")
    if not ok then return false end
    
    -- Prefer using the newer treesitter API if available
    if parsers.has_parser then
      return parsers.has_parser(lang)
    else
      -- Fallback to older method
      local ok2, configs = pcall(require, "nvim-treesitter.configs")
      if not ok2 then return false end
      
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

-- Register the health check with Neovim's built-in health check system
function M.check()
  check_platform()
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