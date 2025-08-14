-- Core utilities for Neovim configuration
-- Contains helper functions, platform detection, and global utilities

local M = {}

-- Helper function to safely require modules with better error reporting
function M.safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    -- Get more detailed error message
    local err_msg = "Could not load module: " .. module
    
    -- Try to check if the module file exists
    local module_path = module:gsub("%.", "/")
    local file_exists = false
    local config_path = vim.fn.stdpath('config')
    
    -- Check in common paths
    for _, path in ipairs({
      config_path .. "/lua/" .. module_path .. ".lua",
      config_path .. "/lua/" .. module_path .. "/init.lua"
    }) do
      if vim.fn.filereadable(path) == 1 then
        file_exists = true
        err_msg = err_msg .. " (File exists but couldn't be loaded, check for syntax errors)"
        break
      end
    end
    
    if not file_exists then
      err_msg = err_msg .. " (File not found)"
    end
    
    vim.notify(err_msg, vim.log.levels.WARN)
    return nil
  end
  return result
end

-- Platform detection utilities
M.platform = {
  is_mac = function() 
    return vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 
  end,
  
  is_linux = function() 
    return vim.fn.has("unix") == 1 and not M.platform.is_mac() 
  end,
  
  is_iterm2 = function()
    return vim.env.TERM_PROGRAM == "iTerm.app" or 
           (vim.env.TERM and string.match(vim.env.TERM, "^iterm")) or 
           vim.env.LC_TERMINAL == "iTerm2"
  end,

  -- Backward compatibility methods for health check
  get_os = function()
    if M.platform.is_mac() then
      return "macos"
    elseif M.platform.is_linux() then
      return "linux"
    else
      return "unknown"
    end
  end,

  get_terminal = function()
    if M.platform.is_iterm2() then
      return "iterm2"
    elseif vim.env.TERM_PROGRAM then
      return vim.env.TERM_PROGRAM:lower()
    elseif vim.env.TERM then
      return vim.env.TERM
    else
      return "unknown"
    end
  end,

  get_arch = function()
    local uname = vim.fn.system('uname -m'):gsub('\n', '')
    if uname:match('arm64') or uname:match('aarch64') then 
      return 'arm64'
    elseif uname:match('x86_64') then 
      return 'x86_64' -- Linux only (Intel Macs not supported)
    else 
      return 'unknown' 
    end
  end,

  is_gui = function()
    return vim.fn.has("gui_running") == 1
  end,

  get_clipboard_config = function()
    if M.platform.is_mac() then
      return { name = "macOS", provider = "pbcopy/pbpaste" }
    elseif M.platform.is_linux() then
      return { name = "Linux", provider = "xclip/wl-clipboard" }
    else
      return {}
    end
  end,

  get_package_manager = function()
    if M.platform.is_mac() then
      if M.platform.command_available('brew') then return 'homebrew' end
      if M.platform.command_available('port') then return 'macports' end
    elseif M.platform.is_linux() then
      if M.platform.command_available('apt') then return 'apt' end
      if M.platform.command_available('dnf') then return 'dnf' end
      if M.platform.command_available('pacman') then return 'pacman' end
      if M.platform.command_available('zypper') then return 'zypper' end
    end
    return 'none'
  end,

  get_terminal_config = function()
    return {
      supports_true_color = true,
      supports_mouse = true,
      supports_undercurl = true,
      support_focus_events = M.platform.is_iterm2(),
      enable_smooth_scrolling = M.platform.is_iterm2(),
    }
  end,

  get_capabilities = function()
    local caps = {}
    
    -- True color support detection
    caps.true_color = vim.env.COLORTERM == "truecolor" or 
                      vim.env.COLORTERM == "24bit" or
                      (vim.env.TERM and vim.env.TERM:match("256color") ~= nil) or
                      M.platform.is_iterm2()
    
    -- Undercurl support (mostly terminal dependent)
    caps.undercurl = M.platform.is_iterm2() or
                     (vim.env.TERM and (
                       vim.env.TERM:match("xterm") ~= nil or

                       vim.env.TERM:match("screen") ~= nil
                     )) or false
    
    -- Mouse support
    caps.mouse = vim.fn.has("mouse") == 1
    
    -- Clipboard support
    caps.clipboard = vim.fn.has("clipboard") == 1 or
                     M.platform.command_available("pbcopy") or  -- macOS
                     M.platform.command_available("xclip") or   -- X11
                     M.platform.command_available("wl-copy")    -- Wayland
    
    -- Focus events (terminal dependent)
    caps.focus_events = M.platform.is_iterm2() or
                        (vim.env.TERM and vim.env.TERM:match("xterm") ~= nil) or
                        false
    
    -- Strikethrough support
    caps.strikethrough = caps.true_color  -- Usually available with true color
    
    -- Italic support
    caps.italic = vim.fn.has("gui_running") == 1 or
                  M.platform.is_iterm2() or
                  (vim.env.TERM and 
                    vim.env.TERM:match("xterm") ~= nil) or false
    
    return caps
  end,

  get_platform_keymaps = function()
    local keymaps = {}
    
    if M.platform.is_mac() then
      -- macOS specific keymaps using Option key
      keymaps = {
        -- Line movement (Option+j/k)
        { mode = "n", lhs = "∆", rhs = ":m .+1<CR>==", desc = "Move line down (Option+j)" },
        { mode = "n", lhs = "˚", rhs = ":m .-2<CR>==", desc = "Move line up (Option+k)" },
        { mode = "i", lhs = "∆", rhs = "<Esc>:m .+1<CR>==gi", desc = "Move line down (Option+j)" },
        { mode = "i", lhs = "˚", rhs = "<Esc>:m .-2<CR>==gi", desc = "Move line up (Option+k)" },
        { mode = "v", lhs = "∆", rhs = ":m '>+1<CR>gv=gv", desc = "Move selection down (Option+j)" },
        { mode = "v", lhs = "˚", rhs = ":m '<-2<CR>gv=gv", desc = "Move selection up (Option+k)" },
        
        -- Word movement (Option+h/l)
        { mode = "n", lhs = "˙", rhs = "b", desc = "Jump word backward (Option+h)" },
        { mode = "n", lhs = "¬", rhs = "w", desc = "Jump word forward (Option+l)" },
        { mode = "i", lhs = "˙", rhs = "<C-o>b", desc = "Jump word backward (Option+h)" },
        { mode = "i", lhs = "¬", rhs = "<C-o>w", desc = "Jump word forward (Option+l)" },
        
        -- macOS-style text editing (Option+Delete)
        { mode = "i", lhs = "∂", rhs = "<C-o>dw", desc = "Delete word forward (Option+Delete)" },
        { mode = "i", lhs = "ƒ", rhs = "<C-w>", desc = "Delete word backward (Option+Backspace)" },
      }
    elseif M.platform.is_linux() then
      -- Linux specific keymaps using Alt key
      keymaps = {
        -- Line movement (Alt+j/k)
        { mode = "n", lhs = "<A-j>", rhs = ":m .+1<CR>==", desc = "Move line down (Alt+j)" },
        { mode = "n", lhs = "<A-k>", rhs = ":m .-2<CR>==", desc = "Move line up (Alt+k)" },
        { mode = "i", lhs = "<A-j>", rhs = "<Esc>:m .+1<CR>==gi", desc = "Move line down (Alt+j)" },
        { mode = "i", lhs = "<A-k>", rhs = "<Esc>:m .-2<CR>==gi", desc = "Move line up (Alt+k)" },
        { mode = "v", lhs = "<A-j>", rhs = ":m '>+1<CR>gv=gv", desc = "Move selection down (Alt+j)" },
        { mode = "v", lhs = "<A-k>", rhs = ":m '<-2<CR>gv=gv", desc = "Move selection up (Alt+k)" },
        
        -- Word movement (Alt+h/l)
        { mode = "n", lhs = "<A-h>", rhs = "b", desc = "Jump word backward (Alt+h)" },
        { mode = "n", lhs = "<A-l>", rhs = "w", desc = "Jump word forward (Alt+l)" },
        { mode = "i", lhs = "<A-h>", rhs = "<C-o>b", desc = "Jump word backward (Alt+h)" },
        { mode = "i", lhs = "<A-l>", rhs = "<C-o>w", desc = "Jump word forward (Alt+l)" },
      }
    end
    
    return keymaps
  end,

  get_clipboard_keymaps = function()
    local keymaps = {}
    local caps = M.platform.get_capabilities()
    
    if caps.clipboard then
      if M.platform.is_mac() then
        -- macOS clipboard keymaps (Cmd+C/V/X)
        keymaps = {
          { mode = "v", lhs = "<D-c>", rhs = '"+y', desc = "Copy to clipboard (Cmd+C)" },
          { mode = "n", lhs = "<D-v>", rhs = '"+p', desc = "Paste from clipboard (Cmd+V)" },
          { mode = "i", lhs = "<D-v>", rhs = '<C-r>+', desc = "Paste from clipboard (Cmd+V)" },
          { mode = "v", lhs = "<D-x>", rhs = '"+d', desc = "Cut to clipboard (Cmd+X)" },
        }
      else
        -- Linux clipboard keymaps (Ctrl+C/V/X)
        keymaps = {
          { mode = "v", lhs = "<C-c>", rhs = '"+y', desc = "Copy to clipboard (Ctrl+C)" },
          { mode = "n", lhs = "<C-v>", rhs = '"+p', desc = "Paste from clipboard (Ctrl+V)" },
          { mode = "i", lhs = "<C-v>", rhs = '<C-r>+', desc = "Paste from clipboard (Ctrl+V)" },
          { mode = "v", lhs = "<C-x>", rhs = '"+d', desc = "Cut to clipboard (Ctrl+X)" },
        }
      end
    end
    
    return keymaps
  end,

  -- Check if a command is available
  command_available = function(cmd)
    if type(cmd) == "string" then
      return vim.fn.executable(cmd) == 1
    elseif type(cmd) == "table" then
      -- Check if any command in the list is available
      for _, c in ipairs(cmd) do
        if vim.fn.executable(c) == 1 then
          return true
        end
      end
      return false
    end
    return false
  end,

  -- Get language-specific tools availability
  get_language_tools = function()
    local tools = {}
    
    -- Go tools
    tools.go = {
      goimports = M.platform.command_available("goimports"),
      gofumpt = M.platform.command_available("gofumpt"),
      golangci_lint = M.platform.command_available("golangci-lint"),
      gomodifytags = M.platform.command_available("gomodifytags"),
      gotests = M.platform.command_available("gotests"),
      dlv = M.platform.command_available("dlv"), -- Delve debugger
    }
    
    -- Node.js tools
    tools.node = {
      npm = M.platform.command_available("npm"),
      yarn = M.platform.command_available("yarn"),
      pnpm = M.platform.command_available("pnpm"),
      node = M.platform.command_available("node"),
    }
    
    -- Python tools
    tools.python = {
      python3 = M.platform.command_available("python3"),
      pip = M.platform.command_available("pip"),
      pip3 = M.platform.command_available("pip3"),
    }
    
    -- Git
    tools.git = {
      git = M.platform.command_available("git"),
    }
    
    return tools
  end,
}

-- Setup function to initialize utilities
function M.setup()
  -- Make safe_require globally available
  _G.safe_require = M.safe_require
  
  -- Make platform detection globally available for backward compatibility
  _G.is_iterm2 = M.platform.is_iterm2
  _G.is_mac = M.platform.is_mac
  _G.is_linux = M.platform.is_linux
  _G.platform = M.platform
  
  -- Set up package path
  local config_path = vim.fn.stdpath('config')
  package.path = config_path .. "/lua/?.lua;" .. 
                 config_path .. "/lua/?/init.lua;" ..
                 config_path .. "/lua/core/?.lua;" ..
                 config_path .. "/lua/plugins/?.lua;" ..
                 config_path .. "/lua/plugins/config/?.lua;" ..
                 package.path

  -- Global configuration flags
  vim.g.skip_ts_tools = true   -- Disable TypeScript tools that were causing issues
  vim.g.skip_treesitter_setup = false
  vim.g.skip_plugin_installer = false
  
  -- Clear treesitter cache on startup to prevent issues
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.defer_fn(function()
        local treesitter_cache = vim.fn.stdpath('cache') .. '/treesitter-vim'
        if vim.fn.isdirectory(treesitter_cache) == 1 then
          local ok, err = pcall(vim.fn.delete, treesitter_cache, 'rf')
          if not ok then
            vim.notify("Failed to clean treesitter cache: " .. tostring(err), vim.log.levels.WARN)
          end
        end
      end, 1000)
    end,
    pattern = "*"
  })
  
  -- Load platform-specific configurations if available (for future extensibility)
  -- Note: This is for future platform-specific modules, not the old user.platform
  -- pcall(function() 
  --   local platform_config = M.safe_require('user.platform_extensions')
  --   if platform_config and platform_config.apply_config then
  --     platform_config.apply_config()
  --   end
  -- end)
  
  -- Set up health check module
  pcall(function() 
    local health = M.safe_require("user.health")
    if health and health.setup then
      health.setup()
    end
  end)
end

return M 