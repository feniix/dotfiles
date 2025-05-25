# Cross-Platform Usage Guide

This guide covers platform-specific features, configurations, and optimizations for the Neovim configuration across macOS and Linux. Windows users should use WSL.

## 🌍 Platform Detection

The configuration automatically detects your platform and applies appropriate settings:

```lua
-- Platform detection (from core/utils.lua)
local utils = require('core.utils')

if utils.platform.is_mac() then
  -- macOS specific settings
elseif utils.platform.is_linux() then  
  -- Linux specific settings
end

-- Or use global functions (backward compatibility)
if is_mac() then
  -- macOS specific settings
elseif is_linux() then
  -- Linux specific settings
end
```

## 🍎 macOS Specific Features

### **System Integration**
- **Clipboard**: Automatic integration with system clipboard via `pbcopy`/`pbpaste`
- **Notifications**: Native macOS notifications for plugin updates and status
- **Finder Integration**: Open files directly from Finder

### **Optimizations**
```lua
-- macOS specific optimizations
if utils.platform.is_mac() then
  vim.opt.clipboard = "unnamedplus"  -- System clipboard integration
  vim.g.python3_host_prog = "/usr/bin/python3"  -- System Python
  
  -- macOS specific keymaps
  vim.keymap.set('n', '<D-s>', ':w<CR>', { desc = 'Save with Cmd+S' })
  vim.keymap.set('n', '<D-v>', '"+p', { desc = 'Paste with Cmd+V' })
end
```

### **Required Tools**
```bash
# Essential tools for macOS
brew install neovim
brew install ripgrep fd fzf git
brew install node python3 go rust

# Optional but recommended
brew install lazygit lazydocker
brew install --cask font-fira-code-nerd-font
```

### **Terminal Recommendations**
- **iTerm2**: Best terminal integration with Neovim
- **Alacritty**: Fast GPU-accelerated terminal
- **Terminal.app**: Built-in terminal (basic support)

## 🐧 Linux Specific Features

### **Distribution Support**
The configuration works across all major Linux distributions:
- **Ubuntu/Debian**: APT package management integration
- **Fedora/RHEL**: DNF package management integration  
- **Arch Linux**: Pacman integration
- **NixOS**: Nix package management support

### **System Integration**
```lua
-- Linux specific optimizations
if utils.platform.is_linux() then
  -- Clipboard integration (X11 or Wayland)
  if os.getenv("WAYLAND_DISPLAY") then
    vim.opt.clipboard = "unnamedplus"  -- Wayland clipboard
  else
    vim.opt.clipboard = "unnamedplus"  -- X11 clipboard (xclip/xsel)
  end
  
  -- Performance optimizations for Linux
  vim.opt.updatetime = 100  -- Faster updates on Linux
end
```

### **Required Tools**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install neovim ripgrep fd-find fzf git curl
sudo apt install nodejs npm python3 python3-pip golang-go

# Fedora
sudo dnf install neovim ripgrep fd-find fzf git curl
sudo dnf install nodejs npm python3 python3-pip golang

# Arch Linux
sudo pacman -S neovim ripgrep fd fzf git curl
sudo pacman -S nodejs npm python python-pip go

# Clipboard support
sudo apt install xclip      # X11
sudo apt install wl-clipboard  # Wayland
```

### **Desktop Environment Integration**
- **GNOME**: Native file picker integration
- **KDE**: Plasma integration for notifications
- **i3/Sway**: Tiling window manager optimizations
- **XFCE**: Lightweight desktop integration

## 🪟 Windows Users: Use WSL

For Windows users, we recommend using Windows Subsystem for Linux (WSL) instead of native Windows support:

### **Why WSL?**
- **Better compatibility**: All Unix tools work natively
- **Consistent experience**: Same configuration works across macOS/Linux/WSL
- **No platform-specific issues**: Avoid Windows path/shell complications
- **Better performance**: Native Unix environment

### **WSL Setup**
```bash
# Install WSL2 with Ubuntu
wsl --install -d Ubuntu

# Install Neovim in WSL
sudo apt update
sudo apt install neovim git curl build-essential

# Clone and setup this configuration
git clone <your-repo> ~/.config/nvim
```

### **WSL Clipboard Integration**
```lua
-- WSL detection and clipboard setup
local function is_wsl()
  local version_file = io.open("/proc/version", "r")
  if version_file then
    local version = version_file:read("*all")
    version_file:close()
    return string.find(version:lower(), "microsoft") ~= nil
  end
  return false
end

if is_wsl() then
  vim.g.clipboard = {
    name = 'WslClipboard',
    copy = {
      ['+'] = 'clip.exe',
      ['*'] = 'clip.exe',
    },
    paste = {
      ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
end
```

## ⚙️ Platform-Specific Configurations

### **Font Handling**
```lua
-- Platform-specific font configuration
local function setup_fonts()
  if utils.platform.is_mac() then
    vim.opt.guifont = "FiraCode Nerd Font:h14"
  elseif utils.platform.is_linux() then
    vim.opt.guifont = "FiraCode Nerd Font 12"
  end
end
```

### **Path Handling**
```lua
-- Unix path utilities (macOS/Linux)
local function get_separator()
  return "/"
end

local function normalize_path(path)
  return path:gsub("\\", "/")
end
```

### **Environment Variables**
```lua
-- Platform-specific environment setup
local function setup_environment()
  if utils.platform.is_mac() then
    -- macOS specific environment
    vim.env.BROWSER = "open"
  elseif utils.platform.is_linux() then
    -- Linux specific environment  
    vim.env.BROWSER = "xdg-open"
  end
end
```

## 🔧 User Customization

### **Platform-Specific User Overrides**
You can customize behavior per platform in your user configuration:

```lua
-- user/config.lua
return {
  core = {
    options = function()
      local opts = {
        -- Common options
        number = true,
        relativenumber = true,
      }
      
      -- Platform-specific options
      if require('core.utils').platform.is_mac() then
        opts.linespace = 2  -- Extra line spacing on macOS
      end
      
      return opts
    end,
    
    keymaps = function()
      local keymaps = {}
      
      -- Platform-specific keymaps
      if require('core.utils').platform.is_mac() then
        keymaps['<D-s>'] = { ':w<CR>', 'Save with Cmd+S' }
        keymaps['<D-v>'] = { '"+p', 'Paste with Cmd+V' }
      end
      
      return keymaps
    end,
  },
}
```

### **Conditional Plugin Loading**
```lua
-- Platform-specific plugins
plugins = {
  specs = function()
    local specs = {}
    
    if require('core.utils').platform.is_mac() then
      table.insert(specs, {
        "rcarriga/nvim-notify",
        opts = { background_colour = "#000000" }  -- macOS dark mode
      })
    end
    
    return specs
  end,
}
```

## 🚀 Performance Optimizations

### **Platform-Specific Performance**
```lua
-- Performance tuning per platform
local function setup_performance()
  if utils.platform.is_mac() then
    -- macOS optimizations
    vim.opt.updatetime = 300
    vim.opt.timeout = true
    vim.opt.timeoutlen = 500
    
  elseif utils.platform.is_linux() then
    -- Linux optimizations
    vim.opt.updatetime = 100  -- Faster on Linux
    vim.opt.lazyredraw = true -- Faster rendering
  end
end
```

### **Resource Management**
```lua
-- Platform-specific resource limits
local function setup_resources()
  local memory_limit = "2g"
  local max_plugins = 100
  
  -- Apply platform-appropriate limits
end
```

## 🐛 Troubleshooting

### **Common Platform Issues**

#### **macOS Issues**
- **Clipboard not working**: Install `pbcopy`/`pbpaste` or use iTerm2
- **Slow startup**: Check for outdated Xcode command line tools
- **Font rendering**: Install proper Nerd Fonts via Homebrew

#### **Linux Issues**  
- **Clipboard not working**: Install `xclip` (X11) or `wl-clipboard` (Wayland)
- **Permission errors**: Check file permissions in `~/.config/nvim`
- **Missing tools**: Install development packages for your distribution

#### **WSL Issues**
- **Clipboard not working**: Ensure `clip.exe` is available in PATH
- **Path issues**: Use Unix paths within WSL environment
- **Performance**: WSL2 performs better than WSL1

### **Health Checks**
Run platform-specific health checks:
```vim
:checkhealth provider  " Check platform providers
:checkhealth clipboard " Check clipboard integration
:checkhealth terminal  " Check terminal capabilities
```

## 📋 Platform Comparison

| Feature | macOS | Linux | WSL |
|---------|-------|-------|-----|
| **Clipboard** | Native | xclip/wl-clipboard | clip.exe |
| **Performance** | Excellent | Excellent | Very Good |
| **Terminal** | iTerm2/Alacritty | Many options | Windows Terminal |
| **Package Manager** | Homebrew | APT/DNF/Pacman | APT (Ubuntu) |
| **Development Tools** | Excellent | Excellent | Excellent |
| **Font Support** | Excellent | Good | Good |
| **Integration** | Native | DE-dependent | Windows/Linux hybrid |

This guide ensures you get the best Neovim experience on macOS, Linux, or WSL! 🎉 