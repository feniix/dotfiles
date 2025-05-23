# Sebastian's Dotfiles

A collection of configuration files for a macOS development environment, following the XDG Base Directory Specification.

## Features

- **XDG Compliance**: Uses `~/.config`, `~/.cache`, `~/.local/share` for cleaner organization
- **Shell**: ZSH with Oh-My-ZSH and bullet-train theme
- **Editors**: Neovim with programming support
- **Terminal**: iTerm2 configuration
- **Git**: Custom aliases and settings with GitHub integration
- **Homebrew**: Managed packages via Brewfile with Apple Silicon support
- **tmux**: Terminal multiplexer with macOS integration
- **macOS**: System defaults for better productivity
- **Fonts**: Nerd Font installation for better terminal and editor experience
- **Cross-Platform**: Basic Linux compatibility for shared environments
- **Error Handling**: Automatic backup and rollback capability
- **Dependency Checking**: Verification of required tools before installation
- **Validation**: Repository structure validation and auto-fixing

## Quick Installation

### One-line Setup (Fresh Install)

```bash
curl -fsSL https://raw.githubusercontent.com/feniix/dotfiles/master/setup.sh | bash
```

### Step-by-Step Installation

1. **Install Command Line Tools:**
   ```bash
   xcode-select --install
   ```

2. **Clone the Repository:**
   ```bash
   git clone https://github.com/feniix/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

3. **Run the Setup Script:**
   ```bash
   ./setup.sh
   ```

## XDG File Locations

After installation, configuration files will be located at:

- **Zsh**: `~/.config/zsh/.zshrc`
- **Neovim**: `~/.config/nvim/init.lua`
- **tmux**: `~/.config/tmux/tmux.conf`
- **Git**: `~/.config/git/config`
- **Homebrew**: `~/.config/homebrew/Brewfile`

## Repository Structure

```
~/dotfiles/
├── scripts/                   # All scripts organized by category
│   ├── setup/                 # Main setup scripts
│   │   ├── setup_xdg.sh       # XDG directory setup
│   │   ├── setup_zsh.sh       # Zsh and Oh-My-Zsh setup
│   │   ├── setup_nvim.sh      # Neovim configuration
│   │   ├── setup_macos.sh     # macOS-specific setup
│   │   ├── setup_linux.sh     # Linux-specific setup
│   │   ├── setup_homebrew.sh  # Homebrew package management
│   │   ├── setup_fonts.sh     # Nerd Font installation
│   │   ├── setup_github.sh    # GitHub integration
│   │   └── cleanup.sh         # Legacy files cleanup
│   ├── macos/                 # macOS-specific scripts
│   │   └── osx-defaults       # macOS defaults script
│   └── utils/                 # Utility scripts
│       ├── flushdns           # DNS cache flush for macOS
│       ├── ssl-cert-check     # SSL certificate validation
│       ├── make-mime.py       # MIME type generator
│       └── view-secrets       # View encrypted files
├── nvim/                      # Neovim configuration
├── fonts/                     # Font configuration and management
├── zsh_custom/                # Custom ZSH themes and plugins
├── Brewfile                   # Homebrew packages list
├── zshrc                      # Zsh main configuration
├── zshenv                     # Zsh environment variables
└── setup.sh                   # Main installation script
```

## Modular Installation

The main setup script provides options for partial installations:

```bash
cd ~/dotfiles && ./setup.sh
```

Then select from the menu:
1. Update existing dotfiles to XDG format
2. Run XDG setup only (for migrating existing configs)
3. Run platform-specific setup only (macOS or Linux)
4. Run Neovim setup only
5. Run Homebrew setup only
6. Set up fonts
7. Set up GitHub integration
8. Clean up legacy files
9. Exit

## Individual Components

You can also run individual setup scripts directly:

```bash
# Install and configure GitHub integration
./scripts/setup/setup_github.sh

# Install programming fonts with Nerd Font patches
./scripts/setup/setup_fonts.sh

# Set up Homebrew and install packages
./scripts/setup/setup_homebrew.sh

# Set up platform-specific configuration
./scripts/setup/setup_macos.sh   # For macOS
./scripts/setup/setup_linux.sh   # For Linux
```

## Safety Features

The dotfiles setup includes several safety features:

- **Dependency Checking**: Verifies required tools are installed before proceeding
- **Repository Validation**: Checks for proper directory structure and files, auto-fixes issues
- **Automatic Backups**: Creates backups of existing configurations before modifying
- **Rollback Capability**: Restores from backup if an error occurs during installation
- **Consistent Logging**: Clear color-coded logging to understand what's happening

## Cross-Platform Support

This dotfiles repository works on:

- **macOS**: Full support for both Intel and Apple Silicon Macs
- **Linux**: Basic support for Debian/Ubuntu, Fedora, and Arch Linux

The setup script automatically detects your platform and runs the appropriate configuration.

## How It Works

- **Symlink Approach**: Configuration files remain in the dotfiles repository and are symlinked to their respective XDG locations
- **Zsh Theme**: The bullet-train theme is installed and linked from the dotfiles repository to the standard oh-my-zsh location
- **Plugin Management**: Plugins like zsh-completions are managed directly without git submodules
- **Modular Setup**: Each component (Neovim, Zsh, macOS settings) has its own setup script for easier maintenance

## Benefits of XDG Structure

- **Cleaner Home Directory**: No more dotfile clutter
- **Better Organization**: Configurations are grouped logically
- **Easier Backup**: All configurations in standardized locations
- **Portability**: Follows established standards

## Notes

- The `~/.zshenv` file is used to set up XDG environment variables
- Some legacy applications may still create dotfiles in the home directory
- Utility scripts are now linked to `~/bin` instead of `~/sbin` for better PATH compatibility
- Backups are stored in `~/.local/share/dotfiles_backup/TIMESTAMP/`

## License

MIT 