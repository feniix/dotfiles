# Neovim Configuration Documentation

This directory contains comprehensive documentation for the modern Neovim configuration in this dotfiles repository.

## 📚 **Documentation Guides**

### Core Features
- [**Colorscheme Guide**](colorscheme_guide.md) - NeoSolarized theme usage, customization, and switching
- [**Which-Key Guide**](WHICH_KEY_GUIDE.md) - Keymap discovery and organization system
- [**TextObjects Guide**](TEXTOBJECTS.md) - TreeSitter-powered smart text objects
- [**Health Check**](HEALTH_CHECK.md) - Configuration diagnostics and troubleshooting
- [**Cross-Platform Support**](CROSS_PLATFORM.md) - Platform-specific optimizations

### Quick Start
1. **Install plugins**: `:PackerSync`
2. **Check health**: `:checkhealth user`
3. **Discover keybindings**: Press `<leader>` (space) and wait for which-key popup
4. **Find files**: `<C-p>` or `<leader>ff`
5. **Search text**: `<C-f>` or `<leader>fg`

## 🚀 **Features Overview**

### **Modern Plugin Stack**
- **📦 Plugin Management**: Packer.nvim with lazy loading
- **🔍 Fuzzy Finding**: Telescope.nvim with FZF integration
- **🗝️ Keymap Discovery**: which-key.nvim with organized groups
- **🌳 Syntax**: TreeSitter with smart text objects
- **🎨 Theme**: NeoSolarized with light/dark switching
- **🔧 LSP Ready**: Prepared for Language Server integration
- **🐛 Debugging**: nvim-dap with UI support

### **Language Support**
- **Go**: Enhanced with vim-go + nvim-dap integration
- **Terraform**: Syntax highlighting and formatting
- **Puppet**: Syntax support
- **JSON/YAML**: Smart indentation and parsing
- **Lua**: Native Neovim configuration language
- **Markdown**: Enhanced editing and preview

### **Text Editing Power**
- **Smart Text Objects**: 15+ TreeSitter-powered text objects (`af`, `if`, `aa`, `ia`, etc.)
- **Code Navigation**: Jump between functions, classes, loops (`]m`, `[m`, `]c`, `[c`)
- **Code Swapping**: Reorganize parameters and methods (`<leader>na`, `<leader>pa`)
- **Auto-completion**: nvim-cmp with multiple sources
- **Git Integration**: Gitsigns with hunk navigation

### **UI/UX Enhancements**
- **Status Line**: Modern lualine with git status
- **Rainbow Brackets**: Color-coded delimiter matching
- **Auto-pairs**: Smart bracket/quote completion
- **Whitespace**: Automatic trailing whitespace management
- **Icons**: Beautiful file and folder icons

## 📁 **File Structure**

```
nvim/
├── init.lua                    # Main entry point
├── init.vim                    # Legacy Vim compatibility
├── lua/
│   ├── init.lua               # Core Lua initialization
│   └── user/                  # User configuration modules
│       ├── plugins.lua        # Plugin definitions & lazy loading
│       ├── telescope.lua      # Fuzzy finder configuration
│       ├── which-key.lua      # Keymap organization
│       ├── treesitter.lua     # Syntax & text objects
│       ├── colorbuddy_setup.lua # Theme configuration
│       ├── options.lua        # Vim settings
│       ├── keymaps.lua        # Key mappings
│       ├── autocmds.lua       # Auto-commands
│       ├── platform.lua       # Cross-platform detection
│       ├── go.lua             # Go-specific features
│       ├── dap.lua            # Debug configuration
│       └── health.lua         # Health check system
└── plugin/                    # Plugin-specific configurations
```

## ⌨️ **Key Mappings Overview**

### **Leader Key Groups** (`<leader>` = Space)
- `<leader>f` - **Find/File** operations (Telescope)
- `<leader>g` - **Git** operations  
- `<leader>b` - **Buffer** management
- `<leader>l` - **LSP/Language** features
- `<leader>d` - **Debug** operations
- `<leader>n/p` - **Text object swapping**

### **Quick Access**
- `<C-p>` - Find files (Telescope)
- `<C-f>` - Live grep (Telescope)
- `<C-s>` - Save file
- `<C-z>` - Undo / `<C-y>` - Redo

### **Text Objects** (use with `v`, `d`, `c`, `y`)
- `af`/`if` - Function (around/inner)
- `ac`/`ic` - Class (around/inner)
- `aa`/`ia` - Argument (around/inner)
- `ai`/`ii` - Conditional (around/inner)
- `al`/`il` - Loop (around/inner)

## 🛠️ **Useful Commands**

### **Plugin Management**
- `:PackerSync` - Install/update all plugins
- `:PackerCompile` - Compile plugin configurations
- `:PackerStatus` - Show plugin status

### **Theme & Appearance**
- `:ToggleTheme` - Switch between light/dark Solarized
- `:Telescope colorscheme` - Preview and switch colorschemes

### **Health & Diagnostics**
- `:checkhealth user` - Run configuration health checks
- `:TSModuleInfo textobjects` - Check TreeSitter text objects
- `:WhichKey` - Show all available keymaps

### **TreeSitter**
- `:TSInstall <language>` - Install language parser
- `:TSUpdate` - Update all parsers
- `:TSPlaygroundToggle` - Visualize syntax tree

### **Go Development** (when in .go files)
- `:GoBuild` - Build Go project
- `:GoTest` - Run tests
- `:GoRun` - Run current file
- `:GoCoverage` - Show test coverage

## 🔧 **Customization**

### **Adding New Plugins**
1. Add to `lua/user/plugins.lua`
2. Create configuration in `lua/user/<plugin-name>.lua`
3. Run `:PackerSync`

### **Custom Keymaps**
- Add to `lua/user/keymaps.lua`
- Update `lua/user/which-key.lua` for discoverability

### **Language Support**
- Add parser to `lua/user/treesitter.lua`
- Configure LSP in `lua/user/lsp.lua` (when created)

## 🚨 **Troubleshooting**

### **Common Issues**
1. **Plugins not working**: Run `:PackerSync` and restart
2. **Slow startup**: Check `:startuptime` for bottlenecks
3. **Keymaps not showing**: Ensure which-key is installed
4. **Text objects not working**: Verify TreeSitter parsers with `:TSModuleInfo`

### **Getting Help**
- `:help nvim-treesitter-textobjects` - Text objects documentation
- `:help telescope.nvim` - Fuzzy finder help
- `:help which-key.nvim` - Keymap help system
- `:checkhealth` - Overall Neovim health

## 📖 **Further Reading**

For detailed information about specific features:

- [**Which-Key Guide**](WHICH_KEY_GUIDE.md) - Master your keybindings
- [**TextObjects Guide**](TEXTOBJECTS.md) - Advanced text manipulation
- [**Colorscheme Guide**](colorscheme_guide.md) - Theme customization
- [**Health Check**](HEALTH_CHECK.md) - Troubleshooting guide

## 🎯 **Philosophy**

This configuration prioritizes:
- **Discoverability** - which-key makes features findable
- **Efficiency** - Smart defaults with powerful customization
- **Modern Tools** - LSP, TreeSitter, Telescope for contemporary development
- **Cross-Platform** - Works consistently across macOS, Linux, Windows
- **Performance** - Lazy loading and optimized startup

Enjoy your enhanced Neovim experience! 🚀 