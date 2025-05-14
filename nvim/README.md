# Modern Neovim Configuration

A fully modular, maintainable Neovim configuration built with Lua. This configuration provides a modern editing experience with LSP integration, Tree-sitter for syntax highlighting, and specialized support for various languages.

## Features

- **Modular Structure**: All functionality is organized into separate modules that can be loaded independently
- **Language-Specific Support**: Specialized modules for Go, Terraform, JSON, YAML, Kubernetes, and TypeScript
- **LSP Integration**: Full Language Server Protocol support for intelligent code completion and analysis
- **Tree-sitter**: Advanced syntax highlighting and code navigation
- **Modern UI**: Statusline, git indicators, and other visual improvements
- **Unified Loading**: Consistent loading mechanism with dependency management and error handling

## Structure

```
lua/
├─ init.lua                    # Main entry point
├─ user/
│  ├─ init.lua                 # Unified loading mechanism
│  ├─ options.lua              # Editor options
│  ├─ plugins.lua              # Plugin configuration
│  ├─ ui.lua                   # UI elements (statusline, colors)
│  ├─ keymaps.lua              # Key bindings
│  ├─ completion.lua           # Code completion
│  ├─ lsp.lua                  # Language Server Protocol
│  ├─ lsp_common.lua           # Common LSP functions
│  ├─ treesitter.lua           # Tree-sitter configuration
│  ├─ setup_treesitter.lua     # Tree-sitter setup helpers
│  ├─ plugin_installer.lua     # Plugin management
│  ├─ config_test.lua          # Configuration testing
│  └─ language-support/        # Language-specific modules
│     ├─ go.lua                # Go support
│     ├─ terraform.lua         # Terraform support
│     ├─ json.lua              # JSON support
│     ├─ yaml.lua              # YAML support
│     ├─ kubernetes.lua        # Kubernetes support
│     └─ typescript.lua        # TypeScript support
```

## Usage

### Installation

1. Clone this repository to your Neovim configuration directory:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.config/nvim
```

2. Start Neovim. Plugins will be automatically installed on first run.

### Commands

- `:CheckConfig` - Verify all modules are loaded correctly
- `:InstallTSParsers` - Manually install TreeSitter parsers
- `:FixVimParser` - Fix the Vim TreeSitter parser

### Adding New Functionality

To add a new module:

1. Create a new file in `lua/user/` with a `setup()` function
2. Add it to the appropriate list in `lua/user/init.lua`

### Adding Language Support

To add a new language module:

1. Create a new file in `lua/user/language-support/` with a `setup()` function
2. Add the language name to the `language_modules` table in `lua/user/init.lua`

## Customization

You can customize this configuration by:

1. Editing `lua/user/options.lua` for editor preferences
2. Modifying `lua/user/plugins.lua` to add or remove plugins
3. Updating `lua/user/keymaps.lua` for custom key bindings
4. Adjusting `lua/user/ui.lua` for visual preferences

## Troubleshooting

If you encounter issues:

1. Run `:CheckConfig` to verify all modules are loaded
2. Check the error messages with `:messages`
3. For TreeSitter issues, try `:InstallTSParsers`

## Credits

This configuration incorporates modern Neovim practices and plugins from the Neovim community. 