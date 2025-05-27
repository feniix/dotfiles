#!/bin/bash
#
# Dotfiles Setup Script
# Sets up development environment with XDG Base Directory Specification compliance

set -e

# Set DOTFILES_DIR based on script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"

# Ensure we're using the absolute path
DOTFILES_DIR="$(cd "$DOTFILES_DIR" && pwd)"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_DIR="$XDG_DATA_HOME/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Scripts directory is under DOTFILES_DIR
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if a command exists
has() {
  type "$1" > /dev/null 2>&1
  return $?
}

# Create backup directory if needed
ensure_backup_dir() {
  if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    log_info "Created backup directory: $BACKUP_DIR"
  fi
}

# Backup a file before modifying it
backup_file() {
  local file="$1"
  if [ -f "$file" ]; then
    ensure_backup_dir
    cp -p "$file" "$BACKUP_DIR/$(basename "$file")"
    log_info "Backed up $file"
  fi
}

# Restore a file from backup
restore_file() {
  local file="$1"
  local basename=$(basename "$file")
  if [ -f "$BACKUP_DIR/$basename" ]; then
    cp -p "$BACKUP_DIR/$basename" "$file"
    log_success "Restored $file from backup"
    return 0
  else
    log_error "No backup found for $file"
    return 1
  fi
}

# Check for required dependencies
check_dependencies() {
  log_info "Checking for required dependencies..."
  
  local missing_deps=0
  
  # Required dependencies
  local deps=("git" "curl" "zsh")
  
  for dep in "${deps[@]}"; do
    if ! has "$dep"; then
      log_error "Missing dependency: $dep"
      missing_deps=$((missing_deps + 1))
    fi
  done
  
  # Optional but recommended dependencies
  local opt_deps=("nvim" "tmux")
  
  for dep in "${opt_deps[@]}"; do
    if ! has "$dep"; then
      log_warning "Optional dependency not found: $dep"
    fi
  done
  
  if [ $missing_deps -gt 0 ]; then
    log_error "$missing_deps required dependencies are missing."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      log_info "On macOS, install dependencies with: brew install git curl zsh"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      log_info "On Debian/Ubuntu, install dependencies with: sudo apt install git curl zsh"
      log_info "On Fedora/RHEL, install dependencies with: sudo dnf install git curl zsh"
      log_info "On Arch Linux, install dependencies with: sudo pacman -S git curl zsh"
    fi
    return 1
  fi
  
  log_success "All required dependencies are installed."
  return 0
}

# Validate the repository structure
validate_repo_structure() {
  log_info "Validating repository structure..."
  
  # Check for required directories
  local required_dirs=("scripts/setup" "scripts/macos" "scripts/utils" "scripts/nvim" "scripts/ssh")
  local missing_dirs=0
  
  for dir in "${required_dirs[@]}"; do
    if [ ! -d "$DOTFILES_DIR/$dir" ]; then
      log_warning "Missing directory: $DOTFILES_DIR/$dir"
      missing_dirs=$((missing_dirs + 1))
    fi
  done
  
  # Check for critical setup scripts
  local required_scripts=(
    "scripts/setup/setup_xdg.sh"
    "scripts/setup/setup_zsh.sh"
    "scripts/setup/setup_nvim.sh"
  )
  local missing_scripts=0
  
  for script in "${required_scripts[@]}"; do
    if [ ! -f "$DOTFILES_DIR/$script" ]; then
      log_error "Missing critical script: $DOTFILES_DIR/$script"
      missing_scripts=$((missing_scripts + 1))
    fi
  done
  
  # Only create directories if missing, don't fail if scripts are missing
  if [ $missing_dirs -gt 0 ]; then
    log_info "Creating missing directories..."
    fix_repo_structure
  fi
  
  if [ $missing_scripts -gt 0 ]; then
    log_error "Critical scripts are missing. Please ensure the repository is complete."
    return 1
  else
    log_success "Repository structure validation passed."
  fi
}

# Fix repository structure if needed
fix_repo_structure() {
  log_info "Creating required directories..."
  
  # Create required directories
  mkdir -p "$SCRIPTS_DIR/setup"
  mkdir -p "$SCRIPTS_DIR/macos"
  mkdir -p "$SCRIPTS_DIR/utils"
  mkdir -p "$SCRIPTS_DIR/nvim"
  mkdir -p "$SCRIPTS_DIR/ssh"
  
  log_success "Directory structure created."
}

# Create necessary XDG directories
setup_xdg() {
  log_info "Setting up XDG Base Directory structure..."
  
  if [ ! -f "$SCRIPTS_DIR/setup/setup_xdg.sh" ]; then
    log_error "XDG setup script not found at $SCRIPTS_DIR/setup/setup_xdg.sh"
    return 1
  fi
  
  # Run the dedicated XDG setup script
  bash "$SCRIPTS_DIR/setup/setup_xdg.sh"
}

# Setup macOS-specific configurations
setup_macos() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    log_info "Setting up macOS-specific configurations..."
    
    if [ ! -f "$SCRIPTS_DIR/setup/setup_macos.sh" ]; then
      log_error "macOS setup script not found at $SCRIPTS_DIR/setup/setup_macos.sh"
      return 1
    fi
    
    # Run the dedicated macOS setup script
    bash "$SCRIPTS_DIR/setup/setup_macos.sh"
  else
    log_info "Not on macOS - skipping macOS-specific setup."
  fi
}

# Setup Linux-specific configurations
setup_linux() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_info "Setting up Linux-specific configurations..."
    
    if [ ! -f "$SCRIPTS_DIR/setup/setup_linux.sh" ]; then
      log_error "Linux setup script not found at $SCRIPTS_DIR/setup/setup_linux.sh"
      log_warning "Skipping Linux-specific setup."
      return 1
    fi
    
    # Run the dedicated Linux setup script
    bash "$SCRIPTS_DIR/setup/setup_linux.sh"
  else
    log_info "Not on Linux - skipping Linux-specific setup."
  fi
}

# Setup asdf version manager
setup_asdf() {
  log_info "Setting up asdf version manager..."
  
  if [ ! -f "$SCRIPTS_DIR/setup/setup_asdf.sh" ]; then
    log_error "asdf setup script not found at $SCRIPTS_DIR/setup/setup_asdf.sh"
    log_warning "Skipping asdf setup."
    return 1
  fi
  
  # Run the dedicated asdf setup script
  bash "$SCRIPTS_DIR/setup/setup_asdf.sh"
}

# Setup Neovim configuration
setup_nvim() {
  log_info "Setting up Neovim configuration..."
  
  if [ ! -f "$SCRIPTS_DIR/setup/setup_nvim.sh" ]; then
    log_error "Neovim setup script not found at $SCRIPTS_DIR/setup/setup_nvim.sh"
    return 1
  fi
  
  # Check if user wants to install plugins
  local install_plugins="$1"
  if [ -z "$install_plugins" ]; then
    read -p "Would you like to install Neovim plugins? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      install_plugins="--install-plugins"
    fi
  fi
  
  # Run the dedicated Neovim setup script
  if [ "$install_plugins" = "--install-plugins" ]; then
    bash "$SCRIPTS_DIR/setup/setup_nvim.sh" --install-plugins
  else
    bash "$SCRIPTS_DIR/setup/setup_nvim.sh"
  fi
  
  # Run health check if nvim is available
  if command -v nvim >/dev/null 2>&1; then
    read -p "Would you like to run Neovim health check? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if [ -f "$SCRIPTS_DIR/nvim/health_check.sh" ]; then
        log_info "Running Neovim health check..."
        bash "$SCRIPTS_DIR/nvim/health_check.sh"
      else
        log_info "Running basic health check..."
        nvim --headless -c 'checkhealth user' -c 'quitall' 2>/dev/null || log_warning "Some health checks failed"
      fi
    fi
  fi
  
  # Show available nvim management scripts
  if [ -d "$SCRIPTS_DIR/nvim" ]; then
    log_info "Neovim management scripts are available at:"
    log_info "  • Complete setup: $SCRIPTS_DIR/nvim/setup_and_check.sh"
    log_info "  • Health check: $SCRIPTS_DIR/nvim/health_check.sh"
    log_info "  • Plugin status: $SCRIPTS_DIR/nvim/check_plugins.sh"
    log_info "  • Quick help: $SCRIPTS_DIR/nvim/nvim_help.sh"
  fi
}

# Install Homebrew packages
setup_homebrew() {
  log_info "Setting up Homebrew packages..."
  
  if [ ! -f "$SCRIPTS_DIR/setup/setup_homebrew.sh" ]; then
    log_error "Homebrew setup script not found at $SCRIPTS_DIR/setup/setup_homebrew.sh"
    log_warning "Skipping Homebrew package installation."
    return 1
  fi
  
  # Run the dedicated Homebrew setup script
  bash "$SCRIPTS_DIR/setup/setup_homebrew.sh"
}

# Setup fonts
setup_fonts() {
  log_info "Setting up fonts..."
  
  if [ ! -f "$SCRIPTS_DIR/setup/setup_fonts.sh" ]; then
    log_error "Fonts setup script not found at $SCRIPTS_DIR/setup/setup_fonts.sh"
    log_warning "Skipping font installation."
    return 1
  fi
  
  # Run the dedicated fonts setup script
  bash "$SCRIPTS_DIR/setup/setup_fonts.sh"
}

# Setup GitHub integration
setup_github() {
  log_info "Setting up GitHub integration..."
  
  if [ ! -f "$SCRIPTS_DIR/setup/setup_github.sh" ]; then
    log_error "GitHub setup script not found at $SCRIPTS_DIR/setup/setup_github.sh"
    log_warning "Skipping GitHub integration setup."
    return 1
  fi
  
  # Run the dedicated GitHub setup script
  bash "$SCRIPTS_DIR/setup/setup_github.sh"
}

# Clean up legacy files
cleanup_dotfiles() {
  log_info "Cleaning up legacy files..."
  
  if [ ! -f "$SCRIPTS_DIR/setup/cleanup.sh" ]; then
    log_error "Cleanup script not found at $SCRIPTS_DIR/setup/cleanup.sh"
    log_warning "Skipping cleanup of legacy files."
    return 1
  fi
  
  # Run the dedicated cleanup script
  bash "$SCRIPTS_DIR/setup/cleanup.sh"
}

# Make scripts executable
make_scripts_executable() {
  log_info "Making scripts executable..."
  find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod +x {} \;
  find "$SCRIPTS_DIR/macos" -type f -exec chmod +x {} \;
  find "$SCRIPTS_DIR/utils" -type f -exec chmod +x {} \;
  chmod +x "$DOTFILES_DIR/setup.sh"
  log_success "All scripts are now executable."
}

# Perform rollback in case of failure
rollback() {
  log_error "An error occurred during setup. Rolling back changes..."
  
  # Restore any backup files
  if [ -d "$BACKUP_DIR" ]; then
    log_info "Restoring files from backup..."
    
    # List of files to restore (if they exist in backup)
    local restore_files=(
      "$HOME/.zshenv"
      "$XDG_CONFIG_HOME/zsh/.zshrc"
      "$XDG_CONFIG_HOME/tmux/tmux.conf"
      "$XDG_CONFIG_HOME/git/config"
      "$XDG_CONFIG_HOME/git/ignore"
      "$HOME/.tmux.conf"
      "$HOME/.gitconfig"
      "$HOME/.ssh/config"
      "$HOME/.vimrc"
      "$XDG_CONFIG_HOME/vim/vimrc"
    )
    
    for file in "${restore_files[@]}"; do
      restore_file "$file" || log_warning "Could not restore $file"
    done
    
    log_success "Rollback completed."
  else
    log_warning "No backup directory found. Could not perform rollback."
  fi
}

# Install or update dotfiles
install_dotfiles() {
  log_info "Setting up dotfiles in XDG locations..."
  
  # Create a trap to handle errors and perform rollback
  trap rollback ERR
  
  # Clone the repository if it doesn't exist yet
  if [ ! -d "$DOTFILES_DIR" ]; then
    log_info "Cloning dotfiles repository..."
    git clone https://github.com/feniix/dotfiles.git "$DOTFILES_DIR"
  fi
  
  # Validate and fix repository structure if needed
  validate_repo_structure
  
  # Make scripts executable
  make_scripts_executable
  
  # Set up XDG directory structure
  setup_xdg
  
  # Link config files to XDG locations
  log_info "Creating symlinks for configuration files..."

  # Back up existing files before creating symlinks
  backup_file "$XDG_CONFIG_HOME/zsh/.zshrc"
  backup_file "$HOME/.zshenv"
  backup_file "$XDG_CONFIG_HOME/tmux/tmux.conf"
  backup_file "$HOME/.tmux.conf"
  backup_file "$XDG_CONFIG_HOME/git/config"
  backup_file "$XDG_CONFIG_HOME/git/ignore"
  backup_file "$HOME/.gitconfig"
  backup_file "$XDG_CONFIG_HOME/ssh/config"
  backup_file "$HOME/.ssh/config"
  backup_file "$HOME/.p10k.zsh"
  backup_file "$HOME/.tool-versions"
  backup_file "$HOME/.vimrc"
  backup_file "$XDG_CONFIG_HOME/vim/vimrc"

  # ZSH configuration
  if [ -f "$DOTFILES_DIR/zshrc" ]; then
    mkdir -p "$XDG_CONFIG_HOME/zsh"
    ln -sf "$DOTFILES_DIR/zshrc" "$XDG_CONFIG_HOME/zsh/.zshrc"
    log_success "Linked zshrc → $XDG_CONFIG_HOME/zsh/.zshrc"
  fi
  
  # Create/update zshenv in home directory
  if [ -f "$DOTFILES_DIR/zshenv" ]; then
    ln -sf "$DOTFILES_DIR/zshenv" "$HOME/.zshenv"
    log_success "Linked zshenv → $HOME/.zshenv"
  fi
  
  # Powerlevel10k configuration
  if [ -f "$DOTFILES_DIR/p10k.zsh" ]; then
    ln -sf "$DOTFILES_DIR/p10k.zsh" "$HOME/.p10k.zsh"
    log_success "Linked p10k.zsh → $HOME/.p10k.zsh"
  fi
  
  # tmux configuration
  if [ -f "$DOTFILES_DIR/tmux.conf" ]; then
    mkdir -p "$XDG_CONFIG_HOME/tmux"
    ln -sf "$DOTFILES_DIR/tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"
    log_success "Linked tmux.conf → $XDG_CONFIG_HOME/tmux/tmux.conf"
    
    # Optional: Create a minimal .tmux.conf in home that sources the XDG config
    # Note: This maintains backward compatibility but violates strict XDG compliance
    read -p "Create legacy ~/.tmux.conf for backward compatibility? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if [ ! -f "$HOME/.tmux.conf" ] || ! grep -q "source-file.*tmux\.conf" "$HOME/.tmux.conf"; then
        echo "# XDG compliant tmux configuration" > "$HOME/.tmux.conf"
        echo "source-file $XDG_CONFIG_HOME/tmux/tmux.conf" >> "$HOME/.tmux.conf"
        log_success "Created minimal .tmux.conf that sources the XDG config"
      fi
    else
      log_info "Skipping legacy ~/.tmux.conf creation for strict XDG compliance"
    fi
  fi
  
  # Git configuration
  if [ -f "$DOTFILES_DIR/gitconfig" ]; then
    mkdir -p "$XDG_CONFIG_HOME/git"
    ln -sf "$DOTFILES_DIR/gitconfig" "$XDG_CONFIG_HOME/git/config"
    log_success "Linked gitconfig → $XDG_CONFIG_HOME/git/config"
    
    # Create a symlink in home directory to the XDG config
    if [ -f "$HOME/.gitconfig" ]; then
      backup_file "$HOME/.gitconfig"
      rm -f "$HOME/.gitconfig"
    fi
    ln -sf "$XDG_CONFIG_HOME/git/config" "$HOME/.gitconfig"
    log_success "Linked $XDG_CONFIG_HOME/git/config → $HOME/.gitconfig"
  else
    log_warning "gitconfig not found at $DOTFILES_DIR/gitconfig"
  fi
  
  if [ -f "$DOTFILES_DIR/gitignore_global" ]; then
    mkdir -p "$XDG_CONFIG_HOME/git"
    ln -sf "$DOTFILES_DIR/gitignore_global" "$XDG_CONFIG_HOME/git/ignore"
    log_success "Linked gitignore_global → $XDG_CONFIG_HOME/git/ignore"
  else
    log_warning "gitignore_global not found at $DOTFILES_DIR/gitignore_global"
  fi
  
  # SSH configuration
  if [ -f "$DOTFILES_DIR/ssh_config" ]; then
    mkdir -p "$XDG_CONFIG_HOME/ssh"
    ln -sf "$DOTFILES_DIR/ssh_config" "$XDG_CONFIG_HOME/ssh/config"
    log_success "Linked ssh_config → $XDG_CONFIG_HOME/ssh/config"
    
    # Always create/overwrite ~/.ssh/config to include our XDG config
    mkdir -p "$HOME/.ssh"
    echo "# XDG-compliant SSH configuration" > "$HOME/.ssh/config"
    echo "Include ~/.config/ssh/config" >> "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    log_success "Created/overwrote ~/.ssh/config to include the XDG config"
  else
    log_warning "ssh_config not found at $DOTFILES_DIR/ssh_config"
  fi

  # Link utility scripts to user's bin directory
  mkdir -p "$HOME/bin"
  for script in "$SCRIPTS_DIR/utils"/*; do
    if [ -f "$script" ]; then
      script_name=$(basename "$script")
      ln -sf "$script" "$HOME/bin/$script_name"
      log_success "Linked $script_name → $HOME/bin/$script_name"
    fi
  done
  
  # Setup asdf tools symlink
  if [ -f "$DOTFILES_DIR/asdf-tool-versions" ]; then
    ln -sf "$DOTFILES_DIR/asdf-tool-versions" "$HOME/.tool-versions"
    log_success "Linked asdf-tool-versions → $HOME/.tool-versions"
  else
    log_warning "asdf-tool-versions not found at $DOTFILES_DIR/asdf-tool-versions"
  fi
  
  # Setup Neovim
  setup_nvim
  
  # Platform-specific setup
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # Run macOS-specific setup if on macOS
    setup_macos
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Run Linux-specific setup if on Linux
    setup_linux
  fi
  
  # Setup oh-my-zsh
  log_info "Setting up oh-my-zsh..."
  bash "$SCRIPTS_DIR/setup/setup_zsh.sh"
  
  # Optional setups - only run if scripts exist
  
  # Setup fonts if script exists
  if [ -f "$SCRIPTS_DIR/setup/setup_fonts.sh" ]; then
    read -p "Would you like to install Nerd Fonts? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      setup_fonts
    fi
  fi
  
  # Setup GitHub integration if script exists
  if [ -f "$SCRIPTS_DIR/setup/setup_github.sh" ]; then
    read -p "Would you like to set up GitHub integration? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      setup_github
    fi
  fi
  
  # Setup Homebrew packages if Homebrew is installed or available
  if command -v brew >/dev/null 2>&1 || [ -f "$SCRIPTS_DIR/setup/setup_homebrew.sh" ]; then
    read -p "Would you like to install Homebrew packages defined in Brewfile? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if [ -f "$SCRIPTS_DIR/setup/setup_homebrew.sh" ]; then
        setup_homebrew
      else
        log_error "setup_homebrew.sh script not found at $SCRIPTS_DIR/setup/setup_homebrew.sh"
        log_info "Skipping Homebrew package installation."
      fi
    else
      log_info "Skipping Homebrew package installation."
    fi
  else
    log_warning "Homebrew not installed and setup script not found."
    log_info "Run the following to install Homebrew first:"
    log_info "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  fi
  
  # Clean up old files
  read -p "Would you like to clean up legacy files? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    cleanup_dotfiles
  fi
  
  # Set up SSH keys
  read -p "Would you like to set up SSH keys? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    setup_ssh_keys
  fi
  
  # Set up asdf version manager
  read -p "Would you like to set up asdf version manager and plugins? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    setup_asdf
  fi
  
  # Remove the error trap
  trap - ERR
  
  log_success "XDG-compliant dotfiles installation completed!"
}

# Setup SSH keys
setup_ssh_keys() {
  log_info "Setting up SSH keys..."
  
  if [ ! -f "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" ]; then
    log_error "SSH keys management script not found at $SCRIPTS_DIR/ssh/manage_ssh_keys.sh"
    log_warning "Skipping SSH keys setup."
    return 1
  fi
  
  # Run the SSH key management script to fix permissions
  bash "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" fix-permissions
  
  # Check if keys have passphrases
  bash "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" check-passphrases
  
  # Ask if the user wants to add passphrases to unprotected keys
  read -p "Would you like to add passphrases to unprotected keys? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Listing your SSH keys..."
    bash "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" list
    
    read -p "Enter the name of the key to add a passphrase to (without path): " key_name
    if [ -n "$key_name" ]; then
      bash "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" add-passphrase "$key_name"
    fi
  fi
  
  # Ask if the user wants to back up their keys
  read -p "Would you like to back up your SSH keys to a secure location? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter backup directory path (default: ~/.ssh_backup): " backup_dir
    backup_dir=${backup_dir:-"$HOME/.ssh_backup"}
    
    bash "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" backup "$backup_dir"
  fi
  
  log_success "SSH keys setup complete."
}

# Main script logic
main() {
  echo "╔════════════════════════════════════════╗"
  echo "║     XDG-compliant Dotfiles Setup       ║"
  echo "╚════════════════════════════════════════╝"

  # Load platform detection and package coordination
  log_info "Loading platform detection..."
  if [ -f "$SCRIPTS_DIR/utils/platform_detection.sh" ]; then
    source "$SCRIPTS_DIR/utils/platform_detection.sh"
    detect_platform
    validate_platform_requirements || {
      log_error "Platform requirements validation failed. Please install missing dependencies and try again."
      exit 1
    }
  else
    log_warning "Platform detection script not found, using legacy dependency checks"
    # Check dependencies first
    check_dependencies || {
      log_error "Missing required dependencies. Please install them and try again."
      exit 1
    }
  fi

  # Load package coordination
  log_info "Setting up package coordination..."
  if [ -f "$SCRIPTS_DIR/utils/package_coordination.sh" ]; then
    source "$SCRIPTS_DIR/utils/package_coordination.sh"
    coordinate_packages
  else
    log_warning "Package coordination script not found, proceeding without coordination"
  fi

if [ -d "$DOTFILES_DIR" ]; then
    log_info "Dotfiles directory already exists."
    log_info "Choose an option:"
    echo "1. Update existing dotfiles to XDG format"
    echo "2. Run XDG setup only (for migrating existing configs)"
    echo "3. Run platform-specific setup only (macOS or Linux)"
    echo "4. Run Neovim setup only"
    echo "5. Run comprehensive Neovim setup & health check"
    echo "6. Run Homebrew setup only"
    echo "7. Set up fonts"
    echo "8. Set up GitHub integration"
    echo "9. Clean up legacy files"
    echo "10. Set up SSH keys"
    echo "11. Set up asdf version manager"
    echo "12. Show platform and package coordination info"
    echo "13. Exit"
    
    read -p "Enter your choice (1-13): " choice
    
    case $choice in
      1)
        install_dotfiles
        ;;
      2)
        validate_repo_structure
        setup_xdg
        log_success "XDG Base Directory structure set up."
        ;;
      3)
        validate_repo_structure
        if [[ "$OSTYPE" == "darwin"* ]]; then
          setup_macos
          log_success "macOS-specific setup complete."
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
          setup_linux
          log_success "Linux-specific setup complete."
        else
          log_error "Unsupported operating system: $OSTYPE"
    exit 1
fi
        ;;
      4)
        validate_repo_structure
        setup_nvim
        log_success "Neovim setup complete."
        ;;
      5)
        validate_repo_structure
        if [ -f "$SCRIPTS_DIR/setup/setup_nvim_complete.sh" ]; then
          log_info "Running complete Neovim setup..."
          bash "$SCRIPTS_DIR/setup/setup_nvim_complete.sh"
        elif [ -f "$SCRIPTS_DIR/nvim/setup_and_check.sh" ]; then
          log_info "Running comprehensive Neovim setup..."
          bash "$SCRIPTS_DIR/nvim/setup_and_check.sh"
        else
          log_warning "Complete setup script not found, running basic setup..."
          setup_nvim --install-plugins
        fi
        log_success "Complete Neovim setup finished."
        ;;
      6)
        validate_repo_structure
        setup_homebrew
        log_success "Homebrew setup complete."
        ;;
      7)
        validate_repo_structure
        setup_fonts
        log_success "Fonts setup complete."
        ;;
      8)
        validate_repo_structure
        setup_github
        log_success "GitHub integration setup complete."
        ;;
      9)
        validate_repo_structure
        cleanup_dotfiles
        log_success "Legacy files cleanup complete."
        ;;
      10)
        validate_repo_structure
        setup_ssh_keys
        log_success "SSH keys setup complete."
        ;;
      11)
        validate_repo_structure
        setup_asdf
        log_success "asdf version manager setup complete."
        ;;
      12)
        echo ""
        log_info "=== Platform Information ==="
        if [ -f "$SCRIPTS_DIR/utils/platform_detection.sh" ]; then
          source "$SCRIPTS_DIR/utils/platform_detection.sh"
          detect_platform
          echo ""
          log_info "=== Package Coordination ==="
          if [ -f "$SCRIPTS_DIR/utils/package_coordination.sh" ]; then
            source "$SCRIPTS_DIR/utils/package_coordination.sh"
            coordinate_packages
            show_coordination_summary
            check_package_conflicts
          fi
        else
          log_error "Platform detection scripts not available"
        fi
        echo ""
        read -p "Press any key to continue..." -n 1 -r
        echo ""
        ;;
      13)
        log_info "Exiting without changes."
        exit 0
        ;;
      *)
        log_error "Invalid choice. Exiting."
        exit 1
        ;;
    esac
  else
    # Fresh install
    install_dotfiles
  fi

  echo ""
  echo "╔════════════════════════════════════════╗"
  echo "║             Setup Complete!            ║"
  echo "╚════════════════════════════════════════╝"
  echo ""
  echo "Your dotfiles now follow the XDG Base Directory Specification."
  log_info "Restart your terminal to apply all changes."
}

# Execute main function
main
