# TODO: Multiplatform Neovim Configuration

This document outlines the roadmap to make the Neovim configuration fully compatible across macOS and Linux platforms. Windows users should use WSL (Windows Subsystem for Linux) for the best experience.

## 🎯 Current Status & Priority

- ✅ **macOS**: Fully functional (PRIMARY FOCUS)
- ⚠️ **Linux**: Mostly functional, needs testing and optimization (PRIMARY FOCUS)
- 🚫 **Windows**: Not supported - use WSL instead

## 🚀 Implementation Priority (macOS/Linux Focus)

1. **Platform Detection & Abstraction** - Foundation for macOS/Linux
2. **Path Management** - Critical for cross-platform compatibility
3. **Plugin Compatibility** - Ensure all plugins work on macOS/Linux
4. **Tool Installation** - Automated setup for macOS/Linux
5. **Performance Optimization** - Platform-specific optimizations

---

## 1. 🔍 Platform Detection & Abstraction (macOS/Linux Focus)

**Problem**: Current configuration assumes macOS/Unix environment  
**Impact**: Foundation for macOS/Linux multiplatform features

### Implementation Plan
- [ ] Create `lua/core/platform.lua` module (macOS/Linux only)
- [ ] Implement OS detection (macOS, Linux)
- [ ] Add architecture detection (x86_64, ARM64)
- [ ] Create platform-specific configuration loading
- [ ] Add terminal detection (iTerm2, GNOME Terminal, etc.)
- [ ] Implement capability detection (true color, undercurl, etc.)

```lua
-- lua/core/platform.lua (macOS/Linux only)
local M = {}

M.os = {
  macos = vim.fn.has('mac') == 1 or vim.fn.has('macunix') == 1,
  linux = vim.fn.has('unix') == 1 and not (vim.fn.has('mac') == 1 or vim.fn.has('macunix') == 1),
}

M.arch = {
  x86_64 = vim.fn.system('uname -m'):match('x86_64') ~= nil,
  arm64 = vim.fn.system('uname -m'):match('arm64') ~= nil or vim.fn.system('uname -m'):match('aarch64') ~= nil,
}

function M.get_os()
  if M.os.macos then return 'macos'
  elseif M.os.linux then return 'linux'
  else return 'unsupported' end
end

function M.get_config_dir()
  return vim.fn.expand('~/.config/nvim')
end

function M.get_data_dir()
  return vim.fn.expand('~/.local/share/nvim')
end

return M
```

---

## 2. 📁 Path Management System (macOS/Linux)

**Problem**: Need consistent path handling across Unix-like systems  
**Impact**: Core functionality for file operations and plugin paths

### Implementation Plan
- [ ] Create `lua/core/paths.lua` module (Unix-focused)
- [ ] Implement cross-platform path utilities for macOS/Linux
- [ ] Add home directory detection
- [ ] Implement executable finding utilities

```lua
-- lua/core/paths.lua (macOS/Linux)
local platform = require('core.platform')
local M = {}

M.sep = '/' -- Unix separator

function M.join(...)
  local parts = {...}
  return table.concat(parts, M.sep)
end

function M.normalize(path)
  -- Unix path normalization
  return path:gsub('\\', '/')
end

function M.expand(path)
  if path:sub(1, 1) == '~' then
    local home = os.getenv('HOME')
    return home .. path:sub(2)
  end
  return path
end

function M.executable(name)
  return vim.fn.executable(name) == 1
end

return M
```

---

## 3. 🔌 Plugin Compatibility Matrix (macOS/Linux Focus)

**Problem**: Ensure all plugins work reliably on macOS and Linux  
**Impact**: Consistent development experience across Unix platforms

### Implementation Plan
- [ ] Audit all current plugins for macOS/Linux compatibility
- [ ] Create platform-specific plugin loading for macOS/Linux
- [ ] Add fallback plugins for platform-specific features
- [ ] Implement conditional plugin configuration

```lua
-- lua/plugins/platform.lua (macOS/Linux)
local platform = require('core.platform')
local M = {}

-- Compatibility matrix (macOS/Linux only)
M.compatibility = {
  -- Core plugins (tested on macOS/Linux)
  ['nvim-treesitter'] = { macos = true, linux = true },
  ['nvim-cmp'] = { macos = true, linux = true },
  ['telescope.nvim'] = { macos = true, linux = true },
  ['gitsigns.nvim'] = { macos = true, linux = true },
  ['vim-go'] = { macos = true, linux = true },
}

function M.is_compatible(plugin_name)
  local compat = M.compatibility[plugin_name]
  if not compat then return true end
  
  local os = platform.get_os()
  if os == 'unsupported' then
    vim.notify('Unsupported OS detected. macOS/Linux only supported.', vim.log.levels.WARN)
    return false
  end
  
  return compat[os] == true
end

function M.get_platform_plugins()
  local plugins = {}
  local os = platform.get_os()
  
  if os == 'macos' then
    -- macOS-specific plugins
    table.insert(plugins, {
      'rcarriga/nvim-notify',
      config = function()
        require('notify').setup({
          background_colour = '#000000', -- Better for macOS dark mode
        })
      end
    })
  elseif os == 'linux' then
    -- Linux-specific plugins
    table.insert(plugins, {
      'rcarriga/nvim-notify',
      config = function()
        require('notify').setup({
          background_colour = '#1e1e1e', -- Better for Linux terminals
        })
      end
    })
  end
  
  return plugins
end

return M
```

---

## 4. 🛠️ Tool Installation & Management (macOS/Linux)

**Problem**: Different package managers between macOS and Linux  
**Impact**: Automated setup and maintenance

### Implementation Plan
- [ ] Create `lua/tools/installer.lua` module (macOS/Linux)
- [ ] Implement macOS Homebrew integration
- [ ] Add Linux package manager detection (apt, dnf, pacman)
- [ ] Create tool availability checking
- [ ] Add automatic tool installation

```lua
-- lua/tools/installer.lua (macOS/Linux)
local platform = require('core.platform')
local paths = require('core.paths')
local M = {}

M.package_managers = {
  macos = {
    homebrew = { cmd = 'brew', available = false },
    macports = { cmd = 'port', available = false },
  },
  linux = {
    apt = { cmd = 'apt', available = false },
    dnf = { cmd = 'dnf', available = false },
    pacman = { cmd = 'pacman', available = false },
    zypper = { cmd = 'zypper', available = false },
  },
}

function M.detect_package_managers()
  local os = platform.get_os()
  local managers = M.package_managers[os]
  
  if not managers or os == 'unsupported' then 
    vim.notify('Package manager detection only supports macOS/Linux', vim.log.levels.WARN)
    return 
  end
  
  for name, manager in pairs(managers) do
    if manager.cmd then
      manager.available = paths.executable(manager.cmd)
    end
  end
end

-- Tool installation mappings (macOS/Linux)
M.tools = {
  go = {
    macos = { homebrew = 'go' },
    linux = { apt = 'golang-go', dnf = 'golang', pacman = 'go' }
  },
  rust = {
    macos = { homebrew = 'rust' },
    linux = { apt = 'rustc', dnf = 'rust', pacman = 'rust' }
  },
  node = {
    macos = { homebrew = 'node' },
    linux = { apt = 'nodejs npm', dnf = 'nodejs npm', pacman = 'nodejs npm' }
  },
}

function M.install_tool(tool_name)
  local os = platform.get_os()
  
  if os == 'macos' then
    return M.install_macos_tool(tool_name)
  elseif os == 'linux' then
    return M.install_linux_tool(tool_name)
  else
    vim.notify('Tool installation only supports macOS/Linux', vim.log.levels.WARN)
    return false
  end
end

return M
```

---

## 🚀 Implementation Roadmap (macOS/Linux Focus)

### Phase 1: Foundation (Week 1-2)
- [ ] Implement platform detection module (macOS/Linux only)
- [ ] Create path management utilities for Unix systems
- [ ] Set up basic platform-specific configuration loading

### Phase 2: Core Compatibility (Week 3-4)
- [ ] Audit and fix plugin compatibility issues on macOS/Linux
- [ ] Implement tool installation framework for Homebrew/apt/dnf/pacman
- [ ] Create platform-specific optimizations for macOS/Linux

### Phase 3: Linux Optimization (Week 5-6)
- [ ] Complete Linux-specific implementations
- [ ] Test all features on Ubuntu 22.04 and Debian 12
- [ ] Create Linux setup documentation
- [ ] Optimize for various Linux terminal emulators

### Phase 4: Testing & Polish (Week 7-8)
- [ ] Implement comprehensive testing framework for macOS/Linux
- [ ] Create CI/CD pipeline for macOS/Linux testing
- [ ] Polish documentation and setup guides
- [ ] Performance optimization and benchmarking

---

## 🪟 Windows Users: Use WSL

For Windows users, we recommend using Windows Subsystem for Linux (WSL) instead of native Windows support:

### Why WSL?
- **Better compatibility**: All Unix tools work natively
- **Consistent experience**: Same configuration works across macOS/Linux/WSL
- **No platform-specific issues**: Avoid Windows path/shell complications
- **Better performance**: Native Unix environment

### WSL Setup
```bash
# Install WSL2 with Ubuntu
wsl --install -d Ubuntu

# Install Neovim in WSL
sudo apt update
sudo apt install neovim git curl build-essential

# Clone and setup this configuration
git clone <your-repo> ~/.config/nvim
```

---

*This configuration focuses on delivering a rock-solid macOS/Linux experience, with WSL providing Windows compatibility.* 