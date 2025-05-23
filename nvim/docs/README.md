# Neovim Configuration Documentation

## Overview

This documentation covers the modular Neovim configuration system with clear separation of concerns, improved modularity, and clean architecture.

## 📚 Documentation Structure

### **Technical Reference** (`docs/modules/`)
Comprehensive technical documentation for each system component:
- [Core Modules Documentation](modules/core.md) - Essential functionality and settings
- [Plugin System Documentation](modules/plugins.md) - Plugin management and configuration
- [User Override System Documentation](modules/user.md) - Complete customization system
- [Language Support Documentation](modules/languages.md) - Multi-language development
- [Health Check Documentation](modules/health.md) - Diagnostic and validation

### **User Guides** (`docs/guides/`)
Practical guides for daily usage and specific features:
- [📖 Guides Overview](guides/README.md) - Complete user guides index
- [🗝️ Which-Key Guide](guides/which-key.md) - Keymap discovery and reference
- [🌿 Diffview Guide](guides/diffview.md) - Git diff and history workflows  
- [🎨 Colorschemes Guide](guides/colorschemes.md) - Theme customization
- [📝 Text Objects Guide](guides/text-objects.md) - Advanced text manipulation
- [🏥 Health Checks Guide](guides/health-checks.md) - System validation
- [🌍 Cross-Platform Guide](guides/cross-platform.md) - Platform-specific features

### **📋 Documentation Integration**
- [Integration Guide](INTEGRATION_GUIDE.md) - How all documentation sources work together
- [Implementation Status](../REORGANIZATION.md) - Complete feature tracking and achievements

## Architecture

The configuration is organized into distinct modules:

### Core Modules (`lua/core/`)
Essential Neovim functionality and settings:
- **init.lua** - Core module loader
- **utils.lua** - Utility functions and platform detection
- **options.lua** - Vim options and settings
- **keymaps.lua** - Global keymaps and shortcuts
- **autocmds.lua** - Autocommands and file type settings

### Plugin System (`lua/plugins/`)
Plugin management with separation of declaration and configuration:
- **init.lua** - Plugin loader (lazy.nvim setup)
- **specs/** - Plugin specifications (what to install)
  - **ui.lua** - UI-related plugins
  - **editor.lua** - Editor enhancement plugins
  - **lsp.lua** - LSP and completion plugins
  - **tools.lua** - Development tools
  - **lang/** - Language-specific plugins
- **config/** - Plugin configurations (how to configure)
  - Language-specific configurations in `lang/`

### User Override System (`lua/user/`)
User-specific overrides and customizations:
- **init.lua** - User module loader
- **config.lua** - User configuration file
- **overrides/** - Override system for core and plugins
- **modules/** - Custom user modules

### Health Check System (`lua/health/`)
Diagnostic and health checking functionality

## Quick Navigation

- [Core Modules Documentation](modules/core.md)
- [Plugin System Documentation](modules/plugins.md)
- [User Override System Documentation](modules/user.md)
- [Language Support Documentation](modules/languages.md)
- [Health Check Documentation](modules/health.md)

## Design Principles

### 1. Separation of Concerns
- **Plugin Declarations** vs **Plugin Configurations**
- **Core Settings** vs **User Overrides**
- **Language-specific** vs **General functionality**

### 2. Modular Architecture
- Each module has a single responsibility
- Clear interfaces between modules
- Easy to enable/disable features
- Minimal interdependencies

### 3. Lazy Loading Strategy
- Plugins load only when needed
- Event-based loading for better performance
- Command and filetype-based loading
- Optimized startup time

### 4. User Customization
- Non-intrusive override system
- Preserve user configurations during updates
- Flexible configuration merging
- Post-setup hooks for custom initialization

## Getting Started

1. **Basic Setup**: The configuration works out of the box with sensible defaults
2. **Customization**: Copy `user/config.lua.example` to `user/config.lua` and modify
3. **Language Support**: Enable/disable language-specific features in user config
4. **Health Checks**: Run `:checkhealth user` to verify your setup

## Performance

- Startup time optimized through lazy loading
- Platform-specific optimizations
- Efficient plugin management
- Minimal overhead for unused features 