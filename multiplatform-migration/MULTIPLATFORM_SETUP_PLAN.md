# Enhanced Multiplatform Dotfiles Setup Plan

## Overview

This document outlines the enhanced plan to make the dotfiles project compatible with both **Ubuntu** and **macOS**, building on the existing implementation in `setup.sh` and leveraging current scripts in `scripts/setup/`.

**Current Status**: Basic multiplatform support exists and works well
**Enhancement Scope**: Refine package management strategy and improve platform detection
**Target Enhancement**: Better integration of package managers with asdf version management

**Target Platforms**:
- **macOS**: Homebrew (via Brewfile) + asdf 0.17+ (via asdf-tool-versions)
- **Ubuntu**: apt (primary) + asdf 0.17+ (via asdf-tool-versions) + snap (fallback)

## Current Implementation Analysis

### ✅ Already Working Well
- **XDG Base Directory Specification**: Fully implemented in `scripts/setup/setup_xdg.sh`
- **Platform Detection**: Basic detection exists in individual scripts
- **asdf Integration**: Modern 0.17+ syntax support in `scripts/setup/setup_asdf.sh`
- **Homebrew Integration**: Complete Brewfile support in `scripts/setup/setup_homebrew.sh`
- **Linux Support**: Comprehensive Ubuntu setup in `scripts/setup/setup_linux.sh`
- **Script Organization**: Well-structured modular approach

### 🔄 Areas for Enhancement
1. **Centralized Platform Detection**: Currently scattered across scripts
2. **Package Manager Coordination**: Better integration between system packages and asdf tools
3. **Ubuntu Snap Fallback**: Add snap support for missing apt packages
4. **Package Overlap Resolution**: Avoid conflicts between package managers

## Enhanced Architecture

### 1. Centralized Platform Detection

**Current**: Each script detects platform individually
**Enhanced**: Central detection with exported environment variables

```bash
# scripts/utils/platform_detection.sh - NEW FILE
detect_platform() {
    # Platform identification
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export DOTFILES_PLATFORM="macos"
        export DOTFILES_ARCH=$(uname -m)  # arm64 or x86_64
        export PRIMARY_PKG_MANAGER="brew"
        export SECONDARY_PKG_MANAGER=""
        export ASDF_PACKAGE_SOURCE="homebrew"
    elif [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -f /etc/lsb-release ]]; then
        export DOTFILES_PLATFORM="ubuntu"
        export DOTFILES_ARCH=$(uname -m)  # x86_64
        export PRIMARY_PKG_MANAGER="apt"
        export SECONDARY_PKG_MANAGER="snap"
        export ASDF_PACKAGE_SOURCE="apt"
    else
        echo "❌ Unsupported platform: $OSTYPE"
        exit 1
    fi
    
    # Tool availability
    export HOMEBREW_AVAILABLE=$(command -v brew >/dev/null && echo "true" || echo "false")
    export SNAP_AVAILABLE=$(command -v snap >/dev/null && echo "true" || echo "false")
    export ASDF_AVAILABLE=$(command -v asdf >/dev/null && echo "true" || echo "false")
    
    log_info "Platform: $DOTFILES_PLATFORM ($DOTFILES_ARCH)"
    log_info "Primary package manager: $PRIMARY_PKG_MANAGER"
    [[ -n "$SECONDARY_PKG_MANAGER" ]] && log_info "Fallback package manager: $SECONDARY_PKG_MANAGER"
}
```

### 2. Enhanced Package Management Strategy

#### macOS Package Strategy
**System Packages**: Homebrew (using existing Brewfile)
**Development Tools**: asdf (using existing asdf-tool-versions)
**Coordination**: asdf installed via Homebrew, tools managed by asdf

```bash
# Enhanced scripts/setup/setup_macos.sh
setup_macos_packages() {
    log_info "🍎 Setting up macOS packages..."
    
    # 1. Install Homebrew if needed (existing logic)
    ensure_homebrew_installed
    
    # 2. Install system packages via Brewfile (existing implementation)
    install_brewfile_packages
    
    # 3. Install asdf via Homebrew (enhanced)
    install_asdf_via_homebrew
    
    # 4. Install development tools via asdf (existing implementation)
    install_asdf_tools
    
    log_success "macOS package setup complete"
}

install_asdf_via_homebrew() {
    if ! command -v asdf >/dev/null; then
        log_info "Installing asdf via Homebrew..."
        brew install asdf
        # Source asdf for current session
        . "$(brew --prefix asdf)/libexec/asdf.sh"
    fi
}
```

#### Ubuntu Package Strategy
**System Packages**: apt (primary)
**Development Tools**: asdf (via apt or manual install)
**Fallback Packages**: snap (for packages not in apt)
**Coordination**: Clear separation of responsibilities

```bash
# Enhanced scripts/setup/setup_ubuntu.sh
setup_ubuntu_packages() {
    log_info "🐧 Setting up Ubuntu packages..."
    
    # 1. Update package lists
    sudo apt update
    
    # 2. Install core system packages via apt
    install_core_apt_packages
    
    # 3. Install asdf via apt or manual
    install_asdf_ubuntu
    
    # 4. Install development tools via asdf
    install_asdf_tools
    
    # 5. Install fallback packages via snap
    install_snap_fallbacks
    
    log_success "Ubuntu package setup complete"
}

install_core_apt_packages() {
    local core_packages=(
        # Core development
        build-essential git curl wget
        # Shell and terminal
        zsh tmux
        # Modern CLI tools (if available in apt)
        ripgrep fd-find fzf
        # Languages available in apt
        python3 python3-pip nodejs npm
        # System utilities
        tree htop jq
        # Font support
        fontconfig fonts-powerline
        # Clipboard support
        xclip
    )
    
    log_info "Installing core packages via apt..."
    sudo apt install -y "${core_packages[@]}"
}

install_asdf_ubuntu() {
    if ! command -v asdf >/dev/null; then
        log_info "Installing asdf on Ubuntu..."
        
        # Try apt first (if available in repos)
        if apt-cache search asdf | grep -q "^asdf "; then
            sudo apt install -y asdf
        else
            # Manual installation
            git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.17.0
            echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
            echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
            # Source for current session
            . "$HOME/.asdf/asdf.sh"
        fi
    fi
}

install_snap_fallbacks() {
    if ! command -v snap >/dev/null; then
        log_warning "Snap not available, skipping snap packages"
        return 0
    fi
    
    local snap_packages=(
        # Development tools not in apt or outdated versions
        "go --classic"              # If golang-go is outdated
        "rust --classic"            # Alternative to rustup
        "code --classic"            # VS Code
        # Modern CLI tools not in apt
        "btop"                      # Modern htop alternative
        "lazygit"                   # Git UI
        "neovim --classic"          # Latest nvim
    )
    
    log_info "Installing fallback packages via snap..."
    
    for package in "${snap_packages[@]}"; do
        local pkg_name=$(echo "$package" | cut -d' ' -f1)
        
        # Check if already installed via other means
        if ! command -v "$pkg_name" >/dev/null; then
            log_info "Installing $package via snap..."
            sudo snap install $package || log_warning "Failed to install $package"
        else
            log_info "$pkg_name already available, skipping snap installation"
        fi
    done
}
```

### 3. Enhanced asdf Integration

**Current**: Works well with 0.17+ syntax
**Enhanced**: Better coordination with system package managers

```bash
# Enhanced scripts/setup/setup_asdf.sh
setup_asdf_enhanced() {
    log_info "🔧 Setting up enhanced asdf integration..."
    
    # 1. Ensure asdf is installed via platform package manager
    ensure_asdf_installed
    
    # 2. Configure asdf environment
    configure_asdf_environment
    
    # 3. Install plugins and tools from asdf-tool-versions
    install_asdf_tools_enhanced
    
    # 4. Verify installation
    verify_asdf_setup
}

ensure_asdf_installed() {
    if ! command -v asdf >/dev/null; then
        case "$DOTFILES_PLATFORM" in
            "macos")
                brew install asdf
                . "$(brew --prefix asdf)/libexec/asdf.sh"
                ;;
            "ubuntu")
                install_asdf_ubuntu  # From enhanced ubuntu setup
                ;;
        esac
    fi
}

install_asdf_tools_enhanced() {
    log_info "Installing tools from asdf-tool-versions..."
    
    # Link tool-versions file
    ln -sf "$DOTFILES_DIR/asdf-tool-versions" "$HOME/.tool-versions"
    
    # Extract and install plugins
    local plugins=($(awk '{print $1}' "$HOME/.tool-versions" | sort -u))
    
    for plugin in "${plugins[@]}"; do
        # Skip if already installed
        if asdf plugin list | grep -q "^$plugin$"; then
            log_info "Plugin $plugin already installed"
            continue
        fi
        
        log_info "Installing asdf plugin: $plugin"
        asdf plugin install "$plugin" || log_warning "Failed to install plugin: $plugin"
    done
    
    # Install all tools
    log_info "Installing tool versions..."
    asdf install || log_warning "Some tools failed to install"
}
```

### 4. Package Coordination Strategy

**Problem**: Avoid conflicts between system packages, Homebrew, and asdf
**Solution**: Clear hierarchy and conflict resolution

```bash
# scripts/utils/package_coordination.sh - NEW FILE
coordinate_packages() {
    log_info "🎯 Coordinating package installations..."
    
    # Define package responsibilities
    case "$DOTFILES_PLATFORM" in
        "macos")
            # Homebrew handles: system tools, libraries, applications
            # asdf handles: development language runtimes
            coordinate_macos_packages
            ;;
        "ubuntu")
            # apt handles: system tools, libraries, base languages
            # asdf handles: development language runtimes (latest versions)
            # snap handles: applications not in apt or needing latest versions
            coordinate_ubuntu_packages
            ;;
    esac
}

coordinate_macos_packages() {
    # Packages that should ONLY be installed via Homebrew
    local homebrew_only=(
        # System tools and libraries
        "git" "curl" "wget" "zsh" "tmux"
        # CLI tools
        "ripgrep" "fd" "fzf" "tree" "htop"
        # Applications
        "iterm2" "visual-studio-code"
    )
    
    # Packages that should ONLY be installed via asdf
    local asdf_only=(
        # Development runtimes (from asdf-tool-versions)
        "golang" "python" "nodejs" "rust" "ruby"
        # Development tools
        "terraform" "kubectl" "helm"
    )
    
    log_info "macOS: Homebrew handles system tools, asdf handles development runtimes"
}

coordinate_ubuntu_packages() {
    # Packages that should be installed via apt (system integration)
    local apt_preferred=(
        # Core system tools
        "git" "curl" "wget" "zsh" "tmux"
        # Build tools
        "build-essential" "python3-pip"
        # Basic CLI tools
        "tree" "htop" "jq"
    )
    
    # Packages that should be installed via asdf (latest versions)
    local asdf_preferred=(
        # Development runtimes
        "golang" "python" "nodejs" "rust" "ruby"
        # Development tools
        "terraform" "kubectl" "helm"
    )
    
    # Packages that should be installed via snap (if not in apt or outdated)
    local snap_fallback=(
        # Modern CLI tools
        "ripgrep" "fd" "lazygit"
        # Applications
        "code" "neovim"
    )
    
    log_info "Ubuntu: apt for system, asdf for dev runtimes, snap for modern tools"
}
```

## Integration with Existing Scripts

### 1. Enhanced Main Setup Script

**Current**: `setup.sh` works well with modular approach
**Enhanced**: Add platform coordination calls

```bash
# Enhanced setup.sh additions
main() {
    # ... existing setup.sh logic ...
    
    # NEW: Add after dependency checks
    source "$SCRIPTS_DIR/utils/platform_detection.sh"
    detect_platform
    
    # NEW: Add before platform-specific setup
    source "$SCRIPTS_DIR/utils/package_coordination.sh"
    coordinate_packages
    
    # ... rest of existing logic ...
}
```

### 2. Script Enhancement Matrix

| Script | Current Status | Enhancement Needed |
|--------|---------------|-------------------|
| `setup_xdg.sh` | ✅ Complete | None |
| `setup_zsh.sh` | ✅ Complete | Minor: Use platform detection |
| `setup_nvim.sh` | ✅ Complete | None |
| `setup_homebrew.sh` | ✅ Complete | Minor: Add coordination checks |
| `setup_asdf.sh` | ✅ Good | Medium: Enhanced coordination |
| `setup_linux.sh` | ✅ Good | Medium: Add snap support |
| `setup_macos.sh` | ✅ Good | Minor: Add coordination |
| `setup_fonts.sh` | ✅ Complete | None |
| `setup_github.sh` | ✅ Complete | None |

## Implementation Phases

### Phase 1: Platform Detection Enhancement ⭐ HIGH PRIORITY
1. Create `scripts/utils/platform_detection.sh`
2. Create `scripts/utils/package_coordination.sh`
3. Update `setup.sh` to use centralized detection
4. Test on both platforms

### Phase 2: Ubuntu Package Enhancement ⭐ MEDIUM PRIORITY
1. Enhance `scripts/setup/setup_linux.sh` with snap support
2. Add package coordination logic
3. Test Ubuntu package installation flow
4. Verify no conflicts between apt/snap/asdf

### Phase 3: asdf Coordination Enhancement ⭐ MEDIUM PRIORITY
1. Enhance `scripts/setup/setup_asdf.sh` with platform coordination
2. Ensure clean integration with system package managers
3. Test development tool installations
4. Verify proper tool precedence

### Phase 4: Testing and Documentation ⭐ LOW PRIORITY
1. Create comprehensive testing script
2. Update README with platform-specific instructions
3. Add troubleshooting guides
4. Performance optimization

## File Changes Required

### New Files
```
scripts/utils/platform_detection.sh     # Central platform detection
scripts/utils/package_coordination.sh   # Package manager coordination
scripts/utils/test_platform.sh          # Platform testing utilities
docs/PLATFORM_SUPPORT.md               # Platform-specific documentation
```

### Enhanced Files
```
setup.sh                               # Add platform detection calls
scripts/setup/setup_linux.sh           # Add snap support
scripts/setup/setup_asdf.sh            # Add coordination logic
scripts/setup/setup_homebrew.sh        # Add conflict checking
scripts/setup/setup_macos.sh           # Add coordination
```

### Configuration Files (No Changes Needed)
```
Brewfile                               # ✅ Already optimized
asdf-tool-versions                     # ✅ Already uses 0.17+ syntax
```

## Benefits of This Enhanced Approach

### 1. **Maintains Current Functionality** ✅
- All existing scripts continue to work
- No breaking changes to current setup
- Builds on proven architecture

### 2. **Adds Smart Coordination** 🧠
- Prevents package manager conflicts
- Optimizes installation order
- Clear responsibility separation

### 3. **Improves Ubuntu Support** 🐧
- Better package availability through snap fallback
- Coordinated package management
- Handles Ubuntu-specific package names

### 4. **Simplifies Maintenance** 🔧
- Centralized platform detection
- Consistent package coordination
- Easier to add new platforms

### 5. **Preserves User Choice** 👤
- Interactive prompts remain
- Optional installations maintained
- Flexible setup options

## Success Metrics

### Technical Success
- [ ] Both platforms install without conflicts
- [ ] All tools from asdf-tool-versions work correctly
- [ ] No duplicate packages across managers
- [ ] XDG compliance maintained

### User Experience Success
- [ ] Single command setup on both platforms
- [ ] Clear error messages and recovery
- [ ] Predictable installation results
- [ ] Fast setup times

This enhanced plan builds on the solid foundation already implemented while adding the specific coordination needed for robust multiplatform support. 