#!/bin/bash
#
# Linux-specific setup script
# Ensures compatibility with Linux distributions for shared configurations

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

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

# Detect Linux distribution
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  else
    echo "unknown"
  fi
}

# Install required packages for Ubuntu/Debian
install_debian_packages() {
  log_info "Installing required packages for Debian/Ubuntu..."
  
  # Package list
  packages=(
    zsh
    curl
    git
    vim
    neovim
    tmux
    build-essential
    python3
    python3-pip
    xclip  # for clipboard support
    fonts-powerline
  )
  
  # Ask for confirmation
  echo "The following packages will be installed:"
  for pkg in "${packages[@]}"; do
    echo "  - $pkg"
  done
  
  read -p "Proceed with installation? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Skipping package installation."
    return 0
  fi
  
  # Update package list
  log_info "Updating package list..."
  sudo apt-get update
  
  # Install packages
  log_info "Installing packages..."
  sudo apt-get install -y "${packages[@]}"
  
  log_success "Debian/Ubuntu packages installed successfully."
}

# Install required packages for Fedora/RHEL
install_fedora_packages() {
  log_info "Installing required packages for Fedora/RHEL..."
  
  # Package list
  packages=(
    zsh
    curl
    git
    vim
    neovim
    tmux
    gcc
    gcc-c++
    make
    python3
    python3-pip
    xclip  # for clipboard support
    powerline-fonts
  )
  
  # Ask for confirmation
  echo "The following packages will be installed:"
  for pkg in "${packages[@]}"; do
    echo "  - $pkg"
  done
  
  read -p "Proceed with installation? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Skipping package installation."
    return 0
  fi
  
  # Install packages
  log_info "Installing packages..."
  sudo dnf install -y "${packages[@]}"
  
  log_success "Fedora/RHEL packages installed successfully."
}

# Install required packages for Arch Linux
install_arch_packages() {
  log_info "Installing required packages for Arch Linux..."
  
  # Package list
  packages=(
    zsh
    curl
    git
    vim
    neovim
    tmux
    base-devel
    python
    python-pip
    xclip  # for clipboard support
    powerline-fonts
  )
  
  # Ask for confirmation
  echo "The following packages will be installed:"
  for pkg in "${packages[@]}"; do
    echo "  - $pkg"
  done
  
  read -p "Proceed with installation? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Skipping package installation."
    return 0
  fi
  
  # Install packages
  log_info "Installing packages..."
  sudo pacman -S --needed "${packages[@]}"
  
  log_success "Arch Linux packages installed successfully."
}

# Set up folder structure for Linux
setup_linux_folders() {
  log_info "Setting up Linux-specific folder structure..."
  
  # Create bin directory for scripts
  mkdir -p "$HOME/bin"
  
  # Make sure XDG directories exist
  mkdir -p "$XDG_CONFIG_HOME"
  mkdir -p "$XDG_DATA_HOME"
  mkdir -p "$XDG_CACHE_HOME"
  mkdir -p "$XDG_STATE_HOME"
  
  # Create additional directories
  mkdir -p "$HOME/.local/share/fonts"
  
  log_success "Linux folder structure set up successfully."
}

# Configure Linux-specific settings
configure_linux_settings() {
  log_info "Configuring Linux-specific settings..."
  
  # Set up PATH in .profile if it doesn't include ~/bin
  if [ -f "$HOME/.profile" ]; then
    if ! grep -q 'PATH="$HOME/bin:$PATH"' "$HOME/.profile"; then
      echo '' >> "$HOME/.profile"
      echo '# Add ~/bin to PATH' >> "$HOME/.profile"
      echo 'if [ -d "$HOME/bin" ] ; then' >> "$HOME/.profile"
      echo '    PATH="$HOME/bin:$PATH"' >> "$HOME/.profile"
      echo 'fi' >> "$HOME/.profile"
      log_info "Added ~/bin to PATH in .profile"
    fi
  else
    echo '# Set PATH so it includes user bin directory' > "$HOME/.profile"
    echo 'if [ -d "$HOME/bin" ] ; then' >> "$HOME/.profile"
    echo '    PATH="$HOME/bin:$PATH"' >> "$HOME/.profile"
    echo 'fi' >> "$HOME/.profile"
    log_info "Created .profile with ~/bin in PATH"
  fi
  
  # Set ZSH as default shell if it's installed
  if command -v zsh &> /dev/null; then
    if [ "$SHELL" != "$(which zsh)" ]; then
      log_info "Setting ZSH as default shell..."
      chsh -s "$(which zsh)"
      log_success "ZSH set as default shell. Will take effect after login."
    else
      log_info "ZSH is already the default shell."
    fi
  else
    log_warning "ZSH is not installed. Cannot set as default shell."
  fi
  
  log_success "Linux-specific settings configured successfully."
}

# Link utility scripts to bin directory
link_scripts() {
  log_info "Linking utility scripts to ~/bin directory..."
  
  # Link all scripts in the utils directory
  for script in "$DOTFILES_DIR/scripts/utils"/*; do
    if [ -f "$script" ]; then
      script_name=$(basename "$script")
      
      # Skip macOS-specific scripts on Linux
      if [[ "$script_name" == "flushdns" ]]; then
        log_info "Skipping macOS-specific script: $script_name"
        continue
      fi
      
      ln -sf "$script" "$HOME/bin/$script_name"
      chmod +x "$HOME/bin/$script_name"
      log_success "Linked $script_name to ~/bin"
    fi
  done
  
  log_success "Utility scripts linked successfully."
}

# Install Homebrew on Linux if requested
install_homebrew_linux() {
  log_info "Homebrew can be installed on Linux, but is not always necessary."
  log_info "Native package managers (apt, dnf, pacman) are often sufficient."
  
  read -p "Do you want to install Homebrew on Linux? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Skipping Homebrew installation."
    return 0
  fi
  
  # Install dependencies
  log_info "Installing Homebrew dependencies..."
  distro=$(detect_distro)
  
  if [[ "$distro" == "ubuntu" || "$distro" == "debian" ]]; then
    sudo apt-get update
    sudo apt-get install -y build-essential procps curl file git
  elif [[ "$distro" == "fedora" || "$distro" == "rhel" || "$distro" == "centos" ]]; then
    sudo dnf groupinstall 'Development Tools'
    sudo dnf install -y procps-ng curl file git
  elif [[ "$distro" == "arch" || "$distro" == "manjaro" ]]; then
    sudo pacman -S --needed base-devel procps-ng curl file git
  else
    log_warning "Unknown distribution. Please install the required dependencies manually."
    log_info "Required packages: build tools (gcc, make), procps, curl, file, git"
  fi
  
  # Install Homebrew
  log_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add Homebrew to PATH
  log_info "Adding Homebrew to PATH..."
  test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
  test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  
  # Check if installation was successful
  if command -v brew &> /dev/null; then
    log_success "Homebrew installed successfully."
    
    # Add to shell configuration
    log_info "Adding Homebrew to shell configuration..."
    if [ -f "$HOME/.profile" ]; then
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
    fi
    
    if [ -f "$HOME/.zprofile" ]; then
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
    
    log_info "You can now use Homebrew to install packages."
    log_info "Consider running: brew install gcc"
  else
    log_error "Homebrew installation failed."
    return 1
  fi
  
  return 0
}

# Fix potential issues with Neovim on Linux
fix_neovim_linux() {
  log_info "Checking Neovim configuration for Linux compatibility..."
  
  # Check if Neovim is installed
  if ! command -v nvim &> /dev/null; then
    log_warning "Neovim is not installed. Skipping fixes."
    return 1
  fi
  
  # Create Python provider if needed
  log_info "Setting up Python provider for Neovim..."
  
  # Install pynvim using pip if not already installed
  if ! pip3 list | grep -q "pynvim"; then
    pip3 install --user pynvim
    log_success "Installed pynvim Python package."
  fi
  
  # Check if Python3 is available and will be properly detected by Neovim
  # The Python path is now automatically handled in lua/user/options.lua
  python3_path=$(which python3)
  if [ -n "$python3_path" ]; then
    log_success "Python3 found at: $python3_path"
    log_info "Python provider will be configured automatically by Neovim."
  else
    log_warning "Python3 not found in PATH. Neovim may have issues with Python plugins."
  fi
  
  log_success "Neovim Linux compatibility checks completed."
}

# Main function
main() {
  # Check if actually running on Linux
  if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    log_error "This script is intended for Linux systems only."
    exit 1
  fi
  
  log_info "Starting Linux-specific setup..."
  
  # Detect distribution
  distro=$(detect_distro)
  log_info "Detected Linux distribution: $distro"
  
  # Setup folder structure
  setup_linux_folders
  
  # Install required packages based on distribution
  case "$distro" in
    ubuntu|debian|pop)
      install_debian_packages
      ;;
    fedora|rhel|centos)
      install_fedora_packages
      ;;
    arch|manjaro)
      install_arch_packages
      ;;
    *)
      log_warning "Unsupported Linux distribution. Package installation skipped."
      log_info "You'll need to install required packages manually."
      ;;
  esac
  
  # Configure Linux-specific settings
  configure_linux_settings
  
  # Link scripts
  link_scripts
  
  # Fix Neovim on Linux
  fix_neovim_linux
  
  # Ask about Homebrew
  install_homebrew_linux
  
  log_success "Linux-specific setup completed successfully!"
  log_info "You may need to log out and log back in for all changes to take effect."
}

# Execute main function
main 