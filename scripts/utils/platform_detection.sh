#!/bin/bash
#
# Platform Detection Script
# Centralized platform detection and environment setup for dotfiles
# This script exports environment variables for use across all setup scripts

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}[PLATFORM]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[PLATFORM]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[PLATFORM]${NC} $1"
}

log_error() {
  echo -e "${RED}[PLATFORM]${NC} $1"
}

# Check if a command exists
has() {
  type "$1" > /dev/null 2>&1
  return $?
}

# Main platform detection function
detect_platform() {
  log_info "Detecting platform and available tools..."
  
  # Platform identification
  if [[ "$OSTYPE" == "darwin"* ]]; then
    export DOTFILES_PLATFORM="macos"
    local arch
    arch=$(uname -m)  # arm64 or x86_64
    export DOTFILES_ARCH="$arch"
    export PRIMARY_PKG_MANAGER="brew"
    export SECONDARY_PKG_MANAGER=""
    export ASDF_PACKAGE_SOURCE="homebrew"
    
    # macOS-specific paths
    if [[ "$DOTFILES_ARCH" == "arm64" ]]; then
      export HOMEBREW_PREFIX="/opt/homebrew"
    else
      export HOMEBREW_PREFIX="/usr/local"
    fi
    
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Detect Linux distribution
    if [[ -f /etc/lsb-release ]]; then
      . /etc/lsb-release
      if [[ "$DISTRIB_ID" == "Ubuntu" ]]; then
        export DOTFILES_PLATFORM="ubuntu"
      else
        export DOTFILES_PLATFORM="linux"
      fi
    elif [[ -f /etc/os-release ]]; then
      . /etc/os-release
      if [[ "$ID" == "ubuntu" ]]; then
        export DOTFILES_PLATFORM="ubuntu"
      else
        export DOTFILES_PLATFORM="linux"
      fi
    else
      export DOTFILES_PLATFORM="linux"
    fi
    
    local arch
    arch=$(uname -m)  # x86_64, aarch64
    export DOTFILES_ARCH="$arch"
    export PRIMARY_PKG_MANAGER="apt"
    export SECONDARY_PKG_MANAGER="snap"
    export ASDF_PACKAGE_SOURCE="apt"
    
  else
    log_error "Unsupported platform: $OSTYPE"
    export DOTFILES_PLATFORM="unsupported"
    return 1
  fi
  
  # Tool availability detection
  local homebrew_check
  homebrew_check=$(has "brew" && echo "true" || echo "false")
  export HOMEBREW_AVAILABLE="$homebrew_check"
  
  local snap_check
  snap_check=$(has "snap" && echo "true" || echo "false")
  export SNAP_AVAILABLE="$snap_check"
  
  local asdf_check
  asdf_check=$(has "asdf" && echo "true" || echo "false")
  export ASDF_AVAILABLE="$asdf_check"
  
  local git_check
  git_check=$(has "git" && echo "true" || echo "false")
  export GIT_AVAILABLE="$git_check"
  
  local curl_check
  curl_check=$(has "curl" && echo "true" || echo "false")
  export CURL_AVAILABLE="$curl_check"
  
  local zsh_check
  zsh_check=$(has "zsh" && echo "true" || echo "false")
  export ZSH_AVAILABLE="$zsh_check"
  local nvim_check
  nvim_check=$(has "nvim" && echo "true" || echo "false")
  export NVIM_AVAILABLE="$nvim_check"
  
  # Package manager specific availability
  if [[ "$DOTFILES_PLATFORM" == "macos" ]]; then
    export APT_AVAILABLE="false"
    export BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
  else
    local apt_check
    apt_check=$(has "apt" && echo "true" || echo "false")
    export APT_AVAILABLE="$apt_check"
    export BREW_PREFIX=""
  fi
  
  # Version information for key tools
  if [[ "$ASDF_AVAILABLE" == "true" ]]; then
    local asdf_ver
    asdf_ver=$(asdf version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
    export ASDF_VERSION="$asdf_ver"
  else
    export ASDF_VERSION="not_installed"
  fi
  
  # Export common paths
  export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
  export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  
  # Display detected information
  log_success "Platform: $DOTFILES_PLATFORM ($DOTFILES_ARCH)"
  log_info "Primary package manager: $PRIMARY_PKG_MANAGER"
  [[ -n "$SECONDARY_PKG_MANAGER" ]] && log_info "Fallback package manager: $SECONDARY_PKG_MANAGER"
  
  # Tool availability summary
  log_info "Tool availability:"
  log_info "  • Homebrew: $HOMEBREW_AVAILABLE"
  [[ "$DOTFILES_PLATFORM" != "macos" ]] && log_info "  • apt: $APT_AVAILABLE"
  [[ "$DOTFILES_PLATFORM" != "macos" ]] && log_info "  • snap: $SNAP_AVAILABLE"
  log_info "  • asdf: $ASDF_AVAILABLE"
  [[ "$ASDF_AVAILABLE" == "true" ]] && log_info "  • asdf version: $ASDF_VERSION"
  log_info "  • git: $GIT_AVAILABLE"
  log_info "  • zsh: $ZSH_AVAILABLE"
  log_info "  • nvim: $NVIM_AVAILABLE"
  
  return 0
}

# Validate platform requirements
validate_platform_requirements() {
  log_info "Validating platform requirements..."
  
  local errors=0
  
  # Critical requirements
  if [[ "$GIT_AVAILABLE" != "true" ]]; then
    log_error "git is required but not available"
    ((errors++))
  fi
  
  if [[ "$CURL_AVAILABLE" != "true" ]]; then
    log_error "curl is required but not available"
    ((errors++))
  fi
  
  # Platform-specific requirements
  case "$DOTFILES_PLATFORM" in
    "macos")
      # Homebrew should be available or installable
      if [[ "$HOMEBREW_AVAILABLE" != "true" ]]; then
        log_warning "Homebrew not available - will need to install"
      fi
      ;;
    "ubuntu"|"linux")
      # apt should be available
      if [[ "$APT_AVAILABLE" != "true" ]]; then
        log_error "apt package manager not available"
        ((errors++))
      fi
      ;;
    *)
      log_error "Unsupported platform: $DOTFILES_PLATFORM"
      ((errors++))
      ;;
  esac
  
  if [[ $errors -eq 0 ]]; then
    log_success "Platform requirements validation passed"
    return 0
  else
    log_error "$errors critical requirements missing"
    return 1
  fi
}

# Get platform-specific package name
get_package_name() {
  local generic_name="$1"
  
  case "$DOTFILES_PLATFORM" in
    "macos")
      case "$generic_name" in
        "find") echo "findutils" ;;
        "sed") echo "gnu-sed" ;;
        "tar") echo "gnu-tar" ;;
        "fd") echo "fd" ;;
        *) echo "$generic_name" ;;
      esac
      ;;
    "ubuntu"|"linux")
      case "$generic_name" in
        "fd") echo "fd-find" ;;
        "bat") echo "batcat" ;;
        *) echo "$generic_name" ;;
      esac
      ;;
    *)
      echo "$generic_name"
      ;;
  esac
}

# Check if this script is being sourced or executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Being executed directly - run detection and show results
  detect_platform
  validate_platform_requirements
else
  # Being sourced - just make functions available
  # Detection will be called by the sourcing script
  true
fi 