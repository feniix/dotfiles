# Cross-Platform Usage Guide

This guide covers platform-specific features, configurations, and optimizations for the Neovim configuration across macOS, Linux, and Windows.

## 🌍 Platform Detection

The configuration automatically detects your platform and applies appropriate settings:

```lua
-- Platform detection (from core/utils.lua)
local utils = require('core.utils')

if utils.is_macos() then
  -- macOS specific settings
elseif utils.is_linux() then  
  -- Linux specific settings
elseif utils.is_windows() then
  -- Windows specific settings
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
if utils.is_macos() then
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
if utils.is_linux() then
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

## 🪟 Windows Specific Features

### **PowerShell Integration**
```lua
-- Windows specific optimizations
if utils.is_windows() then
  -- Use PowerShell as default shell
  vim.opt.shell = "powershell"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
  
  -- Windows path handling
  vim.opt.shellslash = false  -- Use backslashes
end
```

### **WSL Support**
Full support for Windows Subsystem for Linux:
```lua
-- WSL detection and optimizations
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
  -- WSL specific clipboard integration
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

### **Required Tools**
```powershell
# Using Chocolatey
choco install neovim ripgrep fd fzf git
choco install nodejs python3 golang rust

# Using Scoop
scoop install neovim ripgrep fd fzf git
scoop install nodejs python go rust

# Using winget
winget install Neovim.Neovim
winget install BurntSushi.ripgrep.MSVC
winget install sharkdp.fd
```

### **Terminal Recommendations**
- **Windows Terminal**: Modern terminal with excellent Neovim support
- **PowerShell**: Built-in with good integration
- **WSL2**: Linux environment on Windows

## ⚙️ Platform-Specific Configurations

### **Font Handling**
```lua
-- Platform-specific font configuration
local function setup_fonts()
  if utils.is_macos() then
    vim.opt.guifont = "FiraCode Nerd Font:h14"
  elseif utils.is_linux() then
    vim.opt.guifont = "FiraCode Nerd Font 12"
  elseif utils.is_windows() then
    vim.opt.guifont = "FiraCode_NF:h12"
  end
end
```

### **Path Handling**
```lua
-- Cross-platform path utilities
local function get_separator()
  return utils.is_windows() and "\\" or "/"
end

local function normalize_path(path)
  if utils.is_windows() then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end
```

### **Environment Variables**
```lua
-- Platform-specific environment setup
local function setup_environment()
  if utils.is_macos() then
    -- macOS specific environment
    vim.env.BROWSER = "open"
  elseif utils.is_linux() then
    -- Linux specific environment  
    vim.env.BROWSER = "xdg-open"
  elseif utils.is_windows() then
    -- Windows specific environment
    vim.env.BROWSER = "start"
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
      if require('core.utils').is_macos() then
        opts.linespace = 2  -- Extra line spacing on macOS
      elseif require('core.utils').is_windows() then
        opts.encoding = "utf-8"  -- Ensure UTF-8 on Windows
      end
      
      return opts
    end,
    
    keymaps = function()
      local keymaps = {}
      
      -- Platform-specific keymaps
      if require('core.utils').is_macos() then
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
    
    if require('core.utils').is_macos() then
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
  if utils.is_macos() then
    -- macOS optimizations
    vim.opt.updatetime = 300
    vim.opt.timeout = true
    vim.opt.timeoutlen = 500
    
  elseif utils.is_linux() then
    -- Linux optimizations
    vim.opt.updatetime = 100  -- Faster on Linux
    vim.opt.lazyredraw = true -- Faster rendering
    
  elseif utils.is_windows() then
    -- Windows optimizations  
    vim.opt.updatetime = 500  -- More conservative on Windows
    vim.opt.hidden = true     -- Better buffer management
  end
end
```

### **Resource Management**
```lua
-- Platform-specific resource limits
local function setup_resources()
  local memory_limit = utils.is_windows() and "1g" or "2g"
  local max_plugins = utils.is_windows() and 50 or 100
  
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

#### **Windows Issues**
- **PowerShell errors**: Enable script execution with `Set-ExecutionPolicy RemoteSigned`
- **Path issues**: Use forward slashes in configuration paths
- **WSL clipboard**: Install `wslu` package for better integration

### **Health Checks**
Run platform-specific health checks:
```vim
:checkhealth provider  " Check platform providers
:checkhealth clipboard " Check clipboard integration
:checkhealth terminal  " Check terminal capabilities
```

## 📋 Platform Comparison

| Feature | macOS | Linux | Windows |
|---------|-------|-------|---------|
| **Clipboard** | Native | xclip/wl-clipboard | Native/WSL |
| **Performance** | Excellent | Excellent | Good |
| **Terminal** | iTerm2/Alacritty | Many options | Windows Terminal |
| **Package Manager** | Homebrew | APT/DNF/Pacman | Chocolatey/Scoop |
| **Development Tools** | Excellent | Excellent | Good (WSL better) |
| **Font Support** | Excellent | Good | Good |
| **Integration** | Native | DE-dependent | PowerShell/WSL |

This cross-platform guide ensures you get the best Neovim experience regardless of your operating system! 🎉 