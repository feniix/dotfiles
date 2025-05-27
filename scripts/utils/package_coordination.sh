#!/bin/bash
#
# Package Coordination Script
# Manages coordination between different package managers to prevent conflicts
# and ensure proper installation hierarchy

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}[COORDINATION]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[COORDINATION]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[COORDINATION]${NC} $1"
}

log_error() {
  echo -e "${RED}[COORDINATION]${NC} $1"
}

# Main package coordination function
coordinate_packages() {
  log_info "🎯 Setting up package manager coordination..."
  
  # Ensure platform detection has been run
  if [[ -z "$DOTFILES_PLATFORM" ]]; then
    log_error "Platform not detected. Please run platform detection first."
    return 1
  fi
  
  # Define package responsibilities based on platform
  case "$DOTFILES_PLATFORM" in
    "macos")
      coordinate_macos_packages
      ;;
    "ubuntu"|"linux")
      coordinate_ubuntu_packages
      ;;
    *)
      log_error "Unsupported platform for package coordination: $DOTFILES_PLATFORM"
      return 1
      ;;
  esac
  
  log_success "Package coordination setup complete"
}

# macOS package coordination
coordinate_macos_packages() {
  log_info "Setting up macOS package coordination..."
  
  # macOS uses Brewfile as source of truth for Homebrew packages
  export BREWFILE_PATH="${DOTFILES_DIR}/Brewfile"
  
  # asdf tools come from asdf-tool-versions file
  export ASDF_TOOL_VERSIONS_PATH="${DOTFILES_DIR}/asdf-tool-versions"
  
  # Read asdf tools from the actual file
  if [[ -f "$ASDF_TOOL_VERSIONS_PATH" ]]; then
    ASDF_TOOLS=($(awk '{print $1}' "$ASDF_TOOL_VERSIONS_PATH" | sort -u))
  else
    log_warning "asdf-tool-versions file not found at $ASDF_TOOL_VERSIONS_PATH"
    ASDF_TOOLS=()
  fi
  
  # Packages that should NOT be installed via both Homebrew and asdf
  # These are tools that might be in Brewfile but should be managed by asdf instead
  CONFLICTING_PACKAGES=(
    "golang:go"      # Homebrew calls it 'go', asdf calls it 'golang'
    "nodejs:node"    # Homebrew calls it 'node', asdf calls it 'nodejs'  
    "python:python3" # Homebrew calls it 'python3', asdf calls it 'python'
    "rust:rust"      # Both call it 'rust'
    "ruby:ruby"      # Both call it 'ruby'
  )
  
  # Get package counts from Brewfile
  local brew_packages=0
  local brew_casks=0
  local mas_apps=0
  
  if [[ -f "$BREWFILE_PATH" ]]; then
    brew_packages=$(grep -c "^brew " "$BREWFILE_PATH" || echo "0")
    brew_casks=$(grep -c "^cask " "$BREWFILE_PATH" || echo "0")
    mas_apps=$(grep -c "^mas " "$BREWFILE_PATH" || echo "0")
  fi
  
  # Export arrays and paths for use by other scripts
  export ASDF_TOOLS
  export CONFLICTING_PACKAGES
  
  log_info "macOS coordination: Brewfile for system tools, asdf for development runtimes"
  log_info "Brewfile path: $BREWFILE_PATH"
  log_info "Brewfile contents: $brew_packages packages, $brew_casks casks, $mas_apps Mac App Store apps"
  log_info "asdf tools: ${#ASDF_TOOLS[@]} defined from $ASDF_TOOL_VERSIONS_PATH"
  
  # Check for potential conflicts
  check_brewfile_asdf_conflicts
}

# Ubuntu/Linux package coordination
coordinate_ubuntu_packages() {
  log_info "Setting up Ubuntu/Linux package coordination..."
  
  # Define package responsibilities for Ubuntu
  APT_PACKAGES=(
    # Core system tools (MUST come from apt, not Linuxbrew)
    "git" "curl" "wget" "zsh" "tmux"
    # Build tools
    "build-essential" "cmake" "autoconf" "automake"
    # System libraries
    "libssl-dev" "libreadline-dev" "libsqlite3-dev" "zlib1g-dev"
    # Python build dependencies (for asdf python builds)
    "libffi-dev" "libbz2-dev" "liblzma-dev" "libncurses5-dev" "libncursesw5-dev"
    "libmpdec-dev" "libexpat1-dev" "tk-dev" "libgdbm-dev" "libnss3-dev"
    # Python support (system version for compatibility)
    "python3" "python3-pip" "python3-dev"
    # Node.js (basic version for system compatibility)
    "nodejs" "npm"
    # Basic CLI tools (if available in apt)
    "tree" "htop" "jq"
    # Font support
    "fontconfig" "fonts-powerline"
    # Clipboard support
    "xclip"
    # Modern CLI tools (if available)
    "ripgrep" "fd-find" "fzf"
    # Locale support
    "locales"
  )
  
  SNAP_PACKAGES=(
    # Development tools not in apt or outdated versions
    "go:--classic"              # If golang-go is outdated
    "rust:--classic"            # Alternative to rustup
    "code:--classic"            # VS Code
    # Modern CLI tools not in apt
    "btop"                      # Modern htop alternative
    "neovim:--classic"          # Latest nvim (if apt version is old)
  )
  
  # Read asdf tools from the actual file (same as macOS)
  export ASDF_TOOL_VERSIONS_PATH="${DOTFILES_DIR}/asdf-tool-versions"
  
  if [[ -f "$ASDF_TOOL_VERSIONS_PATH" ]]; then
    ASDF_TOOLS=($(awk '{print $1}' "$ASDF_TOOL_VERSIONS_PATH" | sort -u))
  else
    log_warning "asdf-tool-versions file not found at $ASDF_TOOL_VERSIONS_PATH"
    ASDF_TOOLS=()
  fi
  
  # GitHub releases for tools not available elsewhere
  GITHUB_TOOLS=(
    "jesseduffield/lazygit:lazygit"
    "jesseduffield/lazydocker:lazydocker"
    "mikefarah/yq:yq"
  )
  
  # Export arrays for use by other scripts
  export APT_PACKAGES
  export SNAP_PACKAGES
  export ASDF_TOOLS
  export GITHUB_TOOLS
  
  log_info "Ubuntu coordination: apt for system, asdf (via Linuxbrew) for dev runtimes, snap for modern tools"
  log_info "  • apt: System tools, libraries, zsh, git, etc. (${#APT_PACKAGES[@]} packages)"
  log_info "  • Linuxbrew: ONLY for asdf installation (not for system tools)"
  log_info "  • asdf: Development runtimes and tools (${#ASDF_TOOLS[@]} tools)"
  log_info "  • snap: Modern CLI tools and applications (${#SNAP_PACKAGES[@]} packages)"
  log_info "  • GitHub: Direct releases (${#GITHUB_TOOLS[@]} tools)"
}

# Check for conflicts between Brewfile and asdf tools
check_brewfile_asdf_conflicts() {
  if [[ "$DOTFILES_PLATFORM" != "macos" ]] || [[ ! -f "$BREWFILE_PATH" ]]; then
    return 0
  fi
  
  log_info "Checking for conflicts between Brewfile and asdf tools..."
  
  local conflicts_found=0
  
  # Check if any asdf tools are also in Brewfile
  for asdf_tool in "${ASDF_TOOLS[@]}"; do
    # Check for conflicting package names
    for conflict in "${CONFLICTING_PACKAGES[@]}"; do
      local asdf_name="${conflict%%:*}"
      local brew_name="${conflict##*:}"
      
      if [[ "$asdf_tool" == "$asdf_name" ]]; then
        # Check if the Homebrew version is in Brewfile
        if grep -q "^brew '$brew_name'" "$BREWFILE_PATH" || grep -q "^brew \"$brew_name\"" "$BREWFILE_PATH"; then
          log_warning "Potential conflict: $asdf_name (asdf) and $brew_name (Brewfile)"
          log_warning "  Recommendation: Remove '$brew_name' from Brewfile, use asdf version instead"
          ((conflicts_found++))
        fi
      fi
    done
  done
  
  if [[ $conflicts_found -eq 0 ]]; then
    log_success "No conflicts detected between Brewfile and asdf tools"
  else
    log_warning "$conflicts_found potential conflicts found between Brewfile and asdf"
  fi
  
  return $conflicts_found
}

# Check for package conflicts (legacy function, now calls specific checkers)
check_package_conflicts() {
  log_info "Checking for potential package conflicts..."
  
  local conflicts_found=0
  
  case "$DOTFILES_PLATFORM" in
    "macos")
      # Check Brewfile vs asdf conflicts
      check_brewfile_asdf_conflicts
      conflicts_found=$?
      
      # Also check if conflicting packages are actually installed
      for conflict in "${CONFLICTING_PACKAGES[@]}"; do
        local asdf_name="${conflict%%:*}"
        local brew_name="${conflict##*:}"
        
        # Check if both are installed
        if command -v brew >/dev/null && brew list "$brew_name" >/dev/null 2>&1; then
          if command -v asdf >/dev/null && asdf list "$asdf_name" >/dev/null 2>&1; then
            log_warning "Runtime conflict detected: $asdf_name (asdf) and $brew_name (brew) both installed"
            ((conflicts_found++))
          fi
        fi
      done
      ;;
    "ubuntu"|"linux")
      # For Ubuntu, conflicts are less likely since we use different package managers
      # for different purposes, but we can still check
      log_info "Ubuntu: apt (system), asdf (dev tools), snap (modern tools) - conflicts unlikely"
      ;;
  esac
  
  if [[ $conflicts_found -eq 0 ]]; then
    log_success "No package conflicts detected"
  else
    log_warning "$conflicts_found potential conflicts found"
  fi
  
  return $conflicts_found
}

# Get the preferred package manager for a tool
get_preferred_manager() {
  local tool_name="$1"
  
  case "$DOTFILES_PLATFORM" in
    "macos")
      # Check if it's in asdf tools list first (development tools take priority)
      for asdf_tool in "${ASDF_TOOLS[@]}"; do
        if [[ "$asdf_tool" == "$tool_name" ]]; then
          echo "asdf"
          return 0
        fi
      done
      
      # Check if it's in Brewfile
      if [[ -f "$BREWFILE_PATH" ]]; then
        # Check for brew packages
        if grep -q "^brew ['\"]$tool_name['\"]" "$BREWFILE_PATH"; then
          echo "homebrew"
          return 0
        fi
        # Check for casks
        if grep -q "^cask ['\"]$tool_name['\"]" "$BREWFILE_PATH"; then
          echo "homebrew-cask"
          return 0
        fi
      fi
      ;;
      
    "ubuntu"|"linux")
      # Check asdf first (for development tools)
      for asdf_tool in "${ASDF_TOOLS[@]}"; do
        if [[ "$asdf_tool" == "$tool_name" ]]; then
          echo "asdf"
          return 0
        fi
      done
      
      # Check apt packages
      for apt_pkg in "${APT_PACKAGES[@]}"; do
        if [[ "$apt_pkg" == "$tool_name" ]]; then
          echo "apt"
          return 0
        fi
      done
      
      # Check snap packages
      for snap_pkg in "${SNAP_PACKAGES[@]}"; do
        local pkg_name="${snap_pkg%%:*}"
        if [[ "$pkg_name" == "$tool_name" ]]; then
          echo "snap"
          return 0
        fi
      done
      
      # Check GitHub tools
      for github_tool in "${GITHUB_TOOLS[@]}"; do
        local tool_part="${github_tool##*:}"
        if [[ "$tool_part" == "$tool_name" ]]; then
          echo "github"
          return 0
        fi
      done
      ;;
  esac
  
  echo "unknown"
  return 1
}

# Install package via preferred manager
install_via_preferred_manager() {
  local tool_name="$1"
  local preferred_manager
  
  preferred_manager=$(get_preferred_manager "$tool_name")
  
  case "$preferred_manager" in
    "homebrew"|"homebrew-cask")
      log_info "Installing $tool_name via Homebrew (using brew bundle)..."
      if [[ -f "$BREWFILE_PATH" ]]; then
        # Use brew bundle to install from Brewfile
        # This ensures consistency and respects the Brewfile as source of truth
        log_info "Installing all packages from Brewfile..."
        brew bundle install --file="$BREWFILE_PATH"
      else
        log_warning "Brewfile not found, falling back to direct installation"
        if [[ "$preferred_manager" == "homebrew-cask" ]]; then
          brew install --cask "$tool_name"
        else
          brew install "$tool_name"
        fi
      fi
      ;;
    "apt")
      log_info "Installing $tool_name via apt..."
      sudo apt install -y "$tool_name"
      ;;
    "snap")
      # Find the snap package with options
      for snap_pkg in "${SNAP_PACKAGES[@]}"; do
        local pkg_name="${snap_pkg%%:*}"
        if [[ "$pkg_name" == "$tool_name" ]]; then
          local options="${snap_pkg##*:}"
          log_info "Installing $tool_name via snap with options: $options..."
          sudo snap install "$tool_name" $options
          break
        fi
      done
      ;;
    "asdf")
      log_info "Installing $tool_name via asdf..."
      asdf plugin install "$tool_name" 2>/dev/null || true
      asdf install "$tool_name" latest
      asdf global "$tool_name" latest
      ;;
    "github")
      log_info "Installing $tool_name via GitHub releases..."
      # This would need to be implemented with a GitHub releases installer
      log_warning "GitHub releases installation not implemented yet"
      ;;
    *)
      log_warning "No preferred manager found for $tool_name"
      return 1
      ;;
  esac
}

# Show coordination summary
show_coordination_summary() {
  log_info "Package Manager Coordination Summary:"
  log_info "Platform: $DOTFILES_PLATFORM"
  log_info "Primary package manager: $PRIMARY_PKG_MANAGER"
  [[ -n "$SECONDARY_PKG_MANAGER" ]] && log_info "Secondary package manager: $SECONDARY_PKG_MANAGER"
  
  case "$DOTFILES_PLATFORM" in
    "macos")
      echo ""
      log_info "📦 Homebrew packages: Managed via Brewfile ($BREWFILE_PATH)"
      if [[ -f "$BREWFILE_PATH" ]]; then
        local brew_count=$(grep -c "^brew " "$BREWFILE_PATH" || echo "0")
        local cask_count=$(grep -c "^cask " "$BREWFILE_PATH" || echo "0") 
        local mas_count=$(grep -c "^mas " "$BREWFILE_PATH" || echo "0")
        log_info "  • $brew_count brew packages"
        log_info "  • $cask_count cask applications"
        log_info "  • $mas_count Mac App Store apps"
      fi
      log_info "🔧 asdf tools (${#ASDF_TOOLS[@]}): ${ASDF_TOOLS[*]}"
      ;;
    "ubuntu"|"linux")
      echo ""
      log_info "📦 apt packages (${#APT_PACKAGES[@]}): ${APT_PACKAGES[*]}"
      log_info "📱 snap packages (${#SNAP_PACKAGES[@]}): ${SNAP_PACKAGES[*]}"
      log_info "🔧 asdf tools (${#ASDF_TOOLS[@]}): ${ASDF_TOOLS[*]}"
      log_info "🐙 GitHub tools (${#GITHUB_TOOLS[@]}): ${GITHUB_TOOLS[*]}"
      ;;
  esac
}

# Check if this script is being sourced or executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Being executed directly - show coordination info
  # First try to source platform detection if available
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$SCRIPT_DIR/platform_detection.sh" ]]; then
    source "$SCRIPT_DIR/platform_detection.sh"
    detect_platform
  fi
  
  coordinate_packages
  show_coordination_summary
  check_package_conflicts
else
  # Being sourced - just make functions available
  true
fi 