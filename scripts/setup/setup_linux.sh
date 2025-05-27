#!/bin/bash
#
# Enhanced Linux-specific setup script
# Integrates with platform detection and package coordination for Phase 2
# Supports apt (primary), snap (fallback), and asdf (development tools)

set -e

# Get script directory and dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source platform detection and package coordination
if [ -f "$SCRIPT_DIR/../utils/platform_detection.sh" ]; then
  source "$SCRIPT_DIR/../utils/platform_detection.sh"
else
  echo "❌ Platform detection script not found. Please ensure Phase 1 is implemented."
  exit 1
fi

if [ -f "$SCRIPT_DIR/../utils/package_coordination.sh" ]; then
  source "$SCRIPT_DIR/../utils/package_coordination.sh"
else
  echo "❌ Package coordination script not found. Please ensure Phase 1 is implemented."
  exit 1
fi

# XDG directories (will be set by platform detection)
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
  echo -e "${BLUE}[LINUX]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[LINUX]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[LINUX]${NC} $1"
}

log_error() {
  echo -e "${RED}[LINUX]${NC} $1"
}

# Check if a command exists
has() {
  type "$1" > /dev/null 2>&1
  return $?
}

# Enhanced distribution detection (uses platform detection)
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

# Install core apt packages (coordinated with package_coordination.sh)
install_apt_packages() {
  log_info "Installing core packages via apt..."
  
  # Ensure platform coordination has been run
  if [[ -z "${APT_PACKAGES[*]}" ]]; then
    log_error "APT_PACKAGES not defined. Please run package coordination first."
    return 1
  fi
  
  # Show packages to be installed
  log_info "The following apt packages will be installed:"
  for pkg in "${APT_PACKAGES[@]}"; do
    echo "  • $pkg"
  done
  
  # Ask for confirmation
  read -p "Proceed with apt package installation? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Skipping apt package installation."
    return 0
  fi
  
  # Update package list
  log_info "Updating apt package list..."
  sudo apt update
  
  # Install packages one by one to handle missing packages gracefully
  local installed_count=0
  local failed_packages=()
  
  for pkg in "${APT_PACKAGES[@]}"; do
    log_info "Installing $pkg..."
    if sudo apt install -y "$pkg"; then
      ((installed_count++))
      log_success "✓ $pkg installed"
    else
      failed_packages+=("$pkg")
      log_warning "✗ Failed to install $pkg"
    fi
  done
  
  log_success "apt installation complete: $installed_count/${#APT_PACKAGES[@]} packages installed"
  
  if [[ ${#failed_packages[@]} -gt 0 ]]; then
    log_warning "Failed packages: ${failed_packages[*]}"
    log_info "These packages may be available via snap or other sources"
  fi
}

# Install snap packages (fallback for missing apt packages)
install_snap_packages() {
  log_info "Installing fallback packages via snap..."
  
  # Check if snap is available
  if ! has "snap"; then
    log_warning "Snap not available. Installing snapd..."
    if sudo apt install -y snapd; then
      log_success "snapd installed successfully"
      # Reload snap environment
      sudo systemctl enable --now snapd.socket
      sudo ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true
    else
      log_error "Failed to install snapd. Skipping snap packages."
      return 1
    fi
  fi
  
  # Ensure snap packages are defined
  if [[ -z "${SNAP_PACKAGES[*]}" ]]; then
    log_warning "No snap packages defined. Skipping snap installation."
    return 0
  fi
  
  # Show packages to be installed
  log_info "The following snap packages will be installed:"
  for pkg_spec in "${SNAP_PACKAGES[@]}"; do
    local pkg_name="${pkg_spec%%:*}"
    local pkg_options="${pkg_spec##*:}"
    if [[ "$pkg_options" != "$pkg_spec" ]]; then
      echo "  • $pkg_name ($pkg_options)"
    else
      echo "  • $pkg_name"
    fi
  done
  
  # Ask for confirmation
  read -p "Proceed with snap package installation? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Skipping snap package installation."
    return 0
  fi
  
  # Install snap packages
  local installed_count=0
  local failed_packages=()
  
  for pkg_spec in "${SNAP_PACKAGES[@]}"; do
    local pkg_name="${pkg_spec%%:*}"
    local pkg_options="${pkg_spec##*:}"
    
    # Skip if already installed via other means
    if has "$pkg_name"; then
      log_info "⚠️  $pkg_name already available, skipping snap installation"
      continue
    fi
    
    log_info "Installing $pkg_name via snap..."
    
    # Install with options if specified
    if [[ "$pkg_options" != "$pkg_spec" ]] && [[ "$pkg_options" != "$pkg_name" ]]; then
      if sudo snap install "$pkg_name" $pkg_options; then
        ((installed_count++))
        log_success "✓ $pkg_name installed via snap"
      else
        failed_packages+=("$pkg_name")
        log_warning "✗ Failed to install $pkg_name via snap"
      fi
    else
      if sudo snap install "$pkg_name"; then
        ((installed_count++))
        log_success "✓ $pkg_name installed via snap"
      else
        failed_packages+=("$pkg_name")
        log_warning "✗ Failed to install $pkg_name via snap"
      fi
    fi
  done
  
  log_success "snap installation complete: $installed_count packages installed"
  
  if [[ ${#failed_packages[@]} -gt 0 ]]; then
    log_warning "Failed snap packages: ${failed_packages[*]}"
  fi
}

# Install asdf and development tools (modern 0.17+ approach)
install_asdf_tools() {
  log_info "Setting up asdf and development tools..."
  
  # Check if asdf is already installed
  if has "asdf"; then
    log_info "asdf is already installed"
  else
    log_info "Installing asdf using modern 0.17+ approach..."
    
    # Method 1: Try Linuxbrew installation (recommended ONLY for asdf)
    if command -v brew >/dev/null 2>&1; then
      log_info "Installing asdf via existing Linuxbrew..."
      brew install asdf
    elif install_linuxbrew; then
      log_info "Installing asdf via newly installed Linuxbrew..."
      log_warning "Note: Linuxbrew is ONLY used for asdf. System tools come from apt."
      brew install asdf
    else
      log_info "Linuxbrew not available, using fallback installation..."
      install_asdf_fallback
    fi
  fi
  
  # Verify asdf is available
  if ! has "asdf"; then
    log_error "asdf installation failed"
    return 1
  fi
  
  # Configure asdf for current session and shell
  configure_asdf_modern
  
  # Install asdf tools using the existing setup_asdf.sh script
  if [ -f "$SCRIPT_DIR/setup_asdf.sh" ]; then
    log_info "Installing asdf tools using setup_asdf.sh..."
    bash "$SCRIPT_DIR/setup_asdf.sh"
  else
    log_warning "setup_asdf.sh not found. Skipping asdf tools installation."
  fi
}

# Install Linuxbrew (Homebrew for Linux)
install_linuxbrew() {
  log_info "Installing Linuxbrew (Homebrew for Linux)..."
  
  # Check if curl is available
  if ! command -v curl >/dev/null 2>&1; then
    log_error "curl is required to install Linuxbrew"
    return 1
  fi
  
  # Install Linuxbrew
  log_info "Downloading and installing Linuxbrew..."
  if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    # Add Linuxbrew to PATH for current session
    if [ -d "/home/linuxbrew/.linuxbrew" ]; then
      export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -d "$HOME/.linuxbrew" ]; then
      export PATH="$HOME/.linuxbrew/bin:$PATH"
      eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi
    
    # Add to shell configuration
    local shell_config=""
    if [[ "$SHELL" == *"zsh"* ]]; then
      shell_config="$HOME/.zshrc"
    else
      shell_config="$HOME/.bashrc"
    fi
    
    if [ -f "$shell_config" ]; then
      if ! grep -q "linuxbrew" "$shell_config"; then
        log_info "Adding Linuxbrew to shell configuration..."
        echo '' >> "$shell_config"
        echo '# Linuxbrew configuration' >> "$shell_config"
        echo 'if [ -d "/home/linuxbrew/.linuxbrew" ]; then' >> "$shell_config"
        echo '  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> "$shell_config"
        echo '  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$shell_config"
        echo 'elif [ -d "$HOME/.linuxbrew" ]; then' >> "$shell_config"
        echo '  export PATH="$HOME/.linuxbrew/bin:$PATH"' >> "$shell_config"
        echo '  eval "$($HOME/.linuxbrew/bin/brew shellenv)"' >> "$shell_config"
        echo 'fi' >> "$shell_config"
      fi
    fi
    
    log_success "Linuxbrew installed successfully"
    return 0
  else
    log_error "Failed to install Linuxbrew"
    return 1
  fi
}

# Install asdf via fallback methods (when Linuxbrew is not available)
install_asdf_fallback() {
  log_info "Installing asdf via modern installation methods..."
  
  # Method 1: Try go install (if Go is available)
  if command -v go >/dev/null 2>&1; then
    log_info "Installing asdf via 'go install'..."
    if go install github.com/asdf-vm/asdf/cmd/asdf@v0.17.0; then
      log_success "asdf installed via 'go install'"
      return 0
    else
      log_warning "Failed to install asdf via 'go install', trying source build..."
    fi
  fi
  
  # Method 2: Build from source (fallback)
  log_info "Installing asdf by building from source..."
  
  # Create temporary directory
  local temp_dir=$(mktemp -d)
  cd "$temp_dir"
  
  # Clone and build asdf
  if git clone https://github.com/asdf-vm/asdf.git --branch v0.17.0 --depth 1; then
    cd asdf
    
    # Build asdf
    if make; then
      # Install to ~/.local/bin
      mkdir -p "$HOME/.local/bin"
      cp asdf "$HOME/.local/bin/asdf"
      chmod +x "$HOME/.local/bin/asdf"
      
      log_success "asdf built and installed to ~/.local/bin/asdf"
      cd - >/dev/null
      rm -rf "$temp_dir"
      return 0
    else
      log_error "Failed to build asdf from source"
    fi
  else
    log_error "Failed to clone asdf repository"
  fi
  
  # Cleanup on failure
  cd - >/dev/null
  rm -rf "$temp_dir"
  return 1
}

# Configure asdf for modern 0.17+ usage
configure_asdf_modern() {
  log_info "Configuring asdf for modern 0.17+ usage..."
  
  # Determine asdf data directory
  local asdf_data_dir="${ASDF_DATA_DIR:-$HOME/.asdf}"
  
  # Add shims directory to PATH for current session
  local shims_dir="$asdf_data_dir/shims"
  if [[ ":$PATH:" != *":$shims_dir:"* ]]; then
    export PATH="$shims_dir:$PATH"
    log_info "Added asdf shims to PATH for current session"
  fi
  
  # Configure shell for persistent usage
  local shell_config=""
  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi
  
  # Add PATH configuration to shell config if not already present
  if [ -f "$shell_config" ]; then
    if ! grep -q "ASDF.*shims" "$shell_config"; then
      log_info "Adding asdf shims to PATH in $shell_config..."
      echo '' >> "$shell_config"
      echo '# asdf configuration (modern 0.17+ approach)' >> "$shell_config"
      echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> "$shell_config"
      
      # Add completions if using zsh
      if [[ "$SHELL" == *"zsh"* ]]; then
        echo '' >> "$shell_config"
        echo '# asdf completions' >> "$shell_config"
        echo 'fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)' >> "$shell_config"
        echo 'autoload -Uz compinit && compinit' >> "$shell_config"
      fi
    else
      log_info "asdf configuration already present in $shell_config"
    fi
  fi
  
  log_success "asdf modern configuration complete"
}

# Install GitHub releases tools
install_github_tools() {
  log_info "Installing tools from GitHub releases..."
  
  # Ensure GitHub tools are defined
  if [[ -z "${GITHUB_TOOLS[*]}" ]]; then
    log_info "No GitHub tools defined. Skipping GitHub installation."
    return 0
  fi
  
  # Create temporary directory for downloads
  local temp_dir=$(mktemp -d)
  local installed_count=0
  
  for tool_spec in "${GITHUB_TOOLS[@]}"; do
    local repo="${tool_spec%%:*}"
    local tool_name="${tool_spec##*:}"
    
    # Skip if already installed
    if has "$tool_name"; then
      log_info "⚠️  $tool_name already available, skipping GitHub installation"
      continue
    fi
    
    log_info "Installing $tool_name from $repo..."
    
    # This is a simplified implementation - in a real scenario, you'd want
    # more sophisticated GitHub release downloading
    log_warning "GitHub releases installation not fully implemented yet"
    log_info "Please install $tool_name manually from https://github.com/$repo/releases"
  done
  
  # Cleanup
  rm -rf "$temp_dir"
  
  if [[ $installed_count -gt 0 ]]; then
    log_success "GitHub tools installation complete: $installed_count tools installed"
  fi
}

# Set up folder structure for Linux
setup_linux_folders() {
  log_info "Setting up Linux-specific folder structure..."
  
  # Create bin directory for scripts
  mkdir -p "$HOME/bin"
  
  # Make sure XDG directories exist (should already be created by platform detection)
  mkdir -p "$XDG_CONFIG_HOME"
  mkdir -p "$XDG_DATA_HOME"
  mkdir -p "$XDG_CACHE_HOME"
  mkdir -p "$XDG_STATE_HOME"
  
  # Create additional directories
  mkdir -p "$HOME/.local/share/fonts"
  mkdir -p "$HOME/.local/bin"
  
  log_success "Linux folder structure set up successfully."
}

# Configure Linux locales
configure_linux_locales() {
  log_info "Configuring Linux locales..."
  
  # Update package list and install locales
  sudo apt update
  sudo apt install -y locales
  
  # Generate en_US.UTF-8 locale
  sudo locale-gen en_US.UTF-8
  
  # Update system locale
  sudo update-locale LANG=en_US.UTF-8
  
  # Export for current session
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  
  # Add to shell configuration for persistence
  local shell_config=""
  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi
  
  if [ -f "$shell_config" ]; then
    if ! grep -q "LANG=en_US.UTF-8" "$shell_config"; then
      log_info "Adding locale configuration to $shell_config..."
      echo '' >> "$shell_config"
      echo '# Locale configuration' >> "$shell_config"
      echo 'export LANG=en_US.UTF-8' >> "$shell_config"
      echo 'export LC_ALL=en_US.UTF-8' >> "$shell_config"
    fi
  fi
  
  log_success "Linux locales configured successfully"
}

# Configure Linux-specific settings
configure_linux_settings() {
  log_info "Configuring Linux-specific settings..."
  
  # Set up PATH in .profile if it doesn't include ~/bin and ~/.local/bin
  local paths_to_add=("$HOME/bin" "$HOME/.local/bin")
  
  for path_dir in "${paths_to_add[@]}"; do
    if [ -f "$HOME/.profile" ]; then
      if ! grep -q "PATH=\"$path_dir:\$PATH\"" "$HOME/.profile"; then
        echo '' >> "$HOME/.profile"
        echo "# Add $path_dir to PATH" >> "$HOME/.profile"
        echo "if [ -d \"$path_dir\" ] ; then" >> "$HOME/.profile"
        echo "    PATH=\"$path_dir:\$PATH\"" >> "$HOME/.profile"
        echo 'fi' >> "$HOME/.profile"
        log_info "Added $path_dir to PATH in .profile"
      fi
    else
      echo "# Set PATH so it includes user bin directories" > "$HOME/.profile"
      for pd in "${paths_to_add[@]}"; do
        echo "if [ -d \"$pd\" ] ; then" >> "$HOME/.profile"
        echo "    PATH=\"$pd:\$PATH\"" >> "$HOME/.profile"
        echo 'fi' >> "$HOME/.profile"
      done
      log_info "Created .profile with user bin directories in PATH"
      break
    fi
  done
  
  # Set ZSH as default shell if it's installed
  if has "zsh"; then
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
      
      # Skip test scripts and Python cache
      if [[ "$script_name" == "test_"* ]] || [[ "$script_name" == "__pycache__" ]]; then
        continue
      fi
      
      ln -sf "$script" "$HOME/bin/$script_name"
      chmod +x "$HOME/bin/$script_name"
      log_success "Linked $script_name to ~/bin"
    fi
  done
  
  log_success "Utility scripts linked successfully."
}

# Fix potential issues with Neovim on Linux
fix_neovim_linux() {
  log_info "Checking Neovim configuration for Linux compatibility..."
  
  # Check if Neovim is installed
  if ! has "nvim"; then
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
  python3_path=$(which python3)
  if [ -n "$python3_path" ]; then
    log_success "Python3 found at: $python3_path"
    log_info "Python provider will be configured automatically by Neovim."
  else
    log_warning "Python3 not found in PATH. Neovim may have issues with Python plugins."
  fi
  
  log_success "Neovim Linux compatibility checks completed."
}

# Show installation summary
show_installation_summary() {
  log_info "📋 Ubuntu/Linux Installation Summary:"
  echo ""
  
  # Show what was installed
  log_info "Package Manager Status:"
  log_info "  • apt: $(has "apt" && echo "✓ Available" || echo "✗ Not available")"
  log_info "  • snap: $(has "snap" && echo "✓ Available" || echo "✗ Not available")"
  log_info "  • asdf: $(has "asdf" && echo "✓ Available" || echo "✗ Not available")"
  
  echo ""
  log_info "Development Tools:"
  local dev_tools=("git" "curl" "zsh" "nvim" "tmux")
  for tool in "${dev_tools[@]}"; do
    log_info "  • $tool: $(has "$tool" && echo "✓ Installed" || echo "✗ Not found")"
  done
  
  echo ""
  log_info "Modern CLI Tools:"
  local cli_tools=("ripgrep" "fd" "fzf" "btop")
  for tool in "${cli_tools[@]}"; do
    # Check common alternative names
    case "$tool" in
      "ripgrep") tool_cmd="rg" ;;
      "fd") tool_cmd="fd" ;;
      *) tool_cmd="$tool" ;;
    esac
    log_info "  • $tool: $(has "$tool_cmd" && echo "✓ Installed" || echo "✗ Not found")"
  done
  
  echo ""
  if [[ -n "${ASDF_TOOLS[*]}" ]]; then
    log_info "asdf Development Tools:"
    for tool in "${ASDF_TOOLS[@]}"; do
      if has "asdf" && asdf list "$tool" >/dev/null 2>&1; then
        local version=$(asdf current "$tool" 2>/dev/null | awk '{print $2}' || echo "unknown")
        log_info "  • $tool: ✓ $version"
      else
        log_info "  • $tool: ✗ Not installed"
      fi
    done
  fi
}

# Main function
main() {
  log_info "🐧 Starting Enhanced Linux Setup (Phase 2)..."
  
  # Run platform detection first
  if ! detect_platform; then
    log_error "Platform detection failed"
    exit 1
  fi
  
  # Verify we're on Linux
  if [[ "$DOTFILES_PLATFORM" != "ubuntu" && "$DOTFILES_PLATFORM" != "linux" ]]; then
    log_error "This script is intended for Linux systems only. Detected: $DOTFILES_PLATFORM"
    exit 1
  fi
  
  # Run package coordination
  if ! coordinate_packages; then
    log_error "Package coordination failed"
    exit 1
  fi
  
  # Detect specific distribution
  local distro=$(detect_distro)
  log_info "Detected Linux distribution: $distro"
  log_info "Platform: $DOTFILES_PLATFORM ($DOTFILES_ARCH)"
  
  # Setup folder structure
  setup_linux_folders
  
  # Configure locales first (important for package installations)
  configure_linux_locales
  
  # Install packages in coordinated order
  log_info "📦 Installing packages using coordinated approach..."
  
  # 1. Core system packages via apt
  install_apt_packages
  
  # 2. Development tools via asdf
  install_asdf_tools
  
  # 3. Fallback packages via snap
  install_snap_packages
  
  # 4. GitHub releases tools (if any)
  install_github_tools
  
  # Configure Linux-specific settings
  configure_linux_settings
  
  # Link scripts
  link_scripts
  
  # Fix Neovim on Linux
  fix_neovim_linux
  
  # Fix any circular symlinks that might have been created
  if [ -f "$SCRIPT_DIR/../utils/fix_circular_symlinks.sh" ]; then
    log_info "Checking for and fixing any circular symlinks..."
    bash "$SCRIPT_DIR/../utils/fix_circular_symlinks.sh"
  fi
  
  # Show summary
  show_installation_summary
  
  log_success "🎉 Enhanced Linux setup completed successfully!"
  log_info "You may need to log out and log back in for all changes to take effect."
  log_info "Run 'source ~/.profile' to update PATH in current session."
  
  # Check if zsh configuration is properly set up
  if [[ "$SHELL" == *"zsh"* ]] && [[ -f "$HOME/.zshenv" ]]; then
    log_info "💡 If you see Homebrew path errors, restart your shell or run:"
    log_info "   source ~/.zshenv"
    
    # Check for missing zsh plugins
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
      local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
      if [[ ! -d "$custom_dir/plugins/zsh-completions" ]]; then
        log_info "💡 Missing zsh plugins detected. Install them with:"
        log_info "   install_zsh_plugins"
      fi
    fi
  fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi 