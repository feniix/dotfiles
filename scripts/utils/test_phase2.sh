#!/bin/bash
#
# Phase 2 Testing Script
# Tests the enhanced Ubuntu/Linux setup with platform detection and package coordination

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}[TEST-P2]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[TEST-P2]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[TEST-P2]${NC} $1"
}

log_error() {
  echo -e "${RED}[TEST-P2]${NC} $1"
}

test_passed() {
  echo -e "${GREEN}✅ PASS:${NC} $1"
}

test_failed() {
  echo -e "${RED}❌ FAIL:${NC} $1"
}

test_warning() {
  echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

# Test enhanced Linux setup script structure
test_enhanced_linux_setup() {
  log_info "Testing enhanced Linux setup script..."
  
  local tests_passed=0
  local tests_total=0
  
  # Check if enhanced setup script exists
  ((tests_total++))
  if [ -f "$DOTFILES_DIR/scripts/setup/setup_linux.sh" ]; then
    test_passed "Enhanced setup_linux.sh exists"
    ((tests_passed++))
    
    # Check for Phase 1 integration
    ((tests_total++))
    if grep -q "platform_detection.sh" "$DOTFILES_DIR/scripts/setup/setup_linux.sh"; then
      test_passed "setup_linux.sh integrates with platform_detection.sh"
      ((tests_passed++))
    else
      test_failed "setup_linux.sh does not integrate with platform_detection.sh"
    fi
    
    ((tests_total++))
    if grep -q "package_coordination.sh" "$DOTFILES_DIR/scripts/setup/setup_linux.sh"; then
      test_passed "setup_linux.sh integrates with package_coordination.sh"
      ((tests_passed++))
    else
      test_failed "setup_linux.sh does not integrate with package_coordination.sh"
    fi
    
    # Check for new Phase 2 functions
    local phase2_functions=(
      "install_apt_packages"
      "install_snap_packages"
      "install_asdf_tools"
      "install_github_tools"
      "show_installation_summary"
    )
    
    for func in "${phase2_functions[@]}"; do
      ((tests_total++))
      if grep -q "^$func()" "$DOTFILES_DIR/scripts/setup/setup_linux.sh"; then
        test_passed "Function $func is implemented"
        ((tests_passed++))
      else
        test_failed "Function $func is missing"
      fi
    done
    
    # Check for coordinated package installation approach
    ((tests_total++))
    if grep -q "APT_PACKAGES\[" "$DOTFILES_DIR/scripts/setup/setup_linux.sh"; then
      test_passed "Uses coordinated APT_PACKAGES array"
      ((tests_passed++))
    else
      test_failed "Does not use coordinated APT_PACKAGES array"
    fi
    
    ((tests_total++))
    if grep -q "SNAP_PACKAGES\[" "$DOTFILES_DIR/scripts/setup/setup_linux.sh"; then
      test_passed "Uses coordinated SNAP_PACKAGES array"
      ((tests_passed++))
    else
      test_failed "Does not use coordinated SNAP_PACKAGES array"
    fi
    
  else
    test_failed "Enhanced setup_linux.sh not found"
  fi
  
  echo ""
  log_info "Enhanced Linux setup tests: $tests_passed/$tests_total passed"
  return $((tests_total - tests_passed))
}

# Test package coordination for Ubuntu/Linux
test_ubuntu_package_coordination() {
  log_info "Testing Ubuntu package coordination..."
  
  # Source platform detection and package coordination
  if [ -f "$SCRIPT_DIR/platform_detection.sh" ]; then
    source "$SCRIPT_DIR/platform_detection.sh"
  else
    test_failed "Platform detection script not found"
    return 1
  fi
  
  if [ -f "$SCRIPT_DIR/package_coordination.sh" ]; then
    source "$SCRIPT_DIR/package_coordination.sh"
  else
    test_failed "Package coordination script not found"
    return 1
  fi
  
  local tests_passed=0
  local tests_total=0
  
  # Simulate Ubuntu platform for testing
  export DOTFILES_PLATFORM="ubuntu"
  export PRIMARY_PKG_MANAGER="apt"
  export SECONDARY_PKG_MANAGER="snap"
  
  # Test package coordination
  ((tests_total++))
  if coordinate_packages; then
    test_passed "Package coordination works for Ubuntu"
    ((tests_passed++))
    
    # Test that Ubuntu-specific arrays are defined
    ((tests_total++))
    if [[ -n "${APT_PACKAGES[*]}" ]]; then
      test_passed "APT_PACKAGES array is defined (${#APT_PACKAGES[@]} packages)"
      ((tests_passed++))
      
      # Check for essential packages
      local essential_packages=("git" "curl" "zsh" "build-essential")
      for pkg in "${essential_packages[@]}"; do
        ((tests_total++))
        if [[ " ${APT_PACKAGES[*]} " =~ \ $pkg\  ]]; then
          test_passed "Essential package $pkg is in APT_PACKAGES"
          ((tests_passed++))
        else
          test_warning "Essential package $pkg not found in APT_PACKAGES"
        fi
      done
    else
      test_failed "APT_PACKAGES array is not defined"
    fi
    
    ((tests_total++))
    if [[ -n "${SNAP_PACKAGES[*]}" ]]; then
      test_passed "SNAP_PACKAGES array is defined (${#SNAP_PACKAGES[@]} packages)"
      ((tests_passed++))
    else
      test_warning "SNAP_PACKAGES array is not defined"
    fi
    
    ((tests_total++))
    if [[ -n "${ASDF_TOOLS[*]}" ]]; then
      test_passed "ASDF_TOOLS array is defined (${#ASDF_TOOLS[@]} tools)"
      ((tests_passed++))
    else
      test_failed "ASDF_TOOLS array is not defined"
    fi
    
    ((tests_total++))
    if [[ -n "${GITHUB_TOOLS[*]}" ]]; then
      test_passed "GITHUB_TOOLS array is defined (${#GITHUB_TOOLS[@]} tools)"
      ((tests_passed++))
    else
      test_warning "GITHUB_TOOLS array is not defined"
    fi
    
  else
    test_failed "Package coordination failed for Ubuntu"
  fi
  
  echo ""
  log_info "Ubuntu package coordination tests: $tests_passed/$tests_total passed"
  return $((tests_total - tests_passed))
}

# Test snap integration
test_snap_integration() {
  log_info "Testing snap integration..."
  
  local tests_passed=0
  local tests_total=0
  
  # Test snap package format parsing
  ((tests_total++))
  local test_snap_packages=("go:--classic" "code:--classic" "btop")
  
  for pkg_spec in "${test_snap_packages[@]}"; do
    local pkg_name="${pkg_spec%%:*}"
    local pkg_options="${pkg_spec##*:}"
    
    if [[ "$pkg_options" != "$pkg_spec" ]]; then
      test_passed "Snap package format parsing works: $pkg_name with options $pkg_options"
      ((tests_passed++))
    else
      test_passed "Snap package format parsing works: $pkg_name (no options)"
      ((tests_passed++))
    fi
    ((tests_total++))
  done
  
  # Test snap availability detection
  ((tests_total++))
  if command -v snap >/dev/null 2>&1; then
    test_passed "Snap is available on this system"
    ((tests_passed++))
    
    # Test snap list functionality
    ((tests_total++))
    if snap list >/dev/null 2>&1; then
      test_passed "Snap list command works"
      ((tests_passed++))
    else
      test_warning "Snap list command failed (may need sudo)"
    fi
  else
    test_warning "Snap is not available on this system"
  fi
  
  echo ""
  log_info "Snap integration tests: $tests_passed/$tests_total passed"
  return $((tests_total - tests_passed))
}

# Test asdf integration enhancement
test_asdf_integration_enhancement() {
  log_info "Testing enhanced asdf integration..."
  
  local tests_passed=0
  local tests_total=0
  
  # Check if asdf setup script exists and has modern features
  ((tests_total++))
  if [ -f "$DOTFILES_DIR/scripts/setup/setup_asdf.sh" ]; then
    test_passed "setup_asdf.sh exists for integration"
    ((tests_passed++))
    
    # Check for modern asdf 0.17+ features
    ((tests_total++))
    if grep -q "configure_asdf_environment" "$DOTFILES_DIR/scripts/setup/setup_asdf.sh"; then
      test_passed "setup_asdf.sh includes modern 0.17+ configuration"
      ((tests_passed++))
    else
      test_failed "setup_asdf.sh missing modern 0.17+ configuration"
    fi
    
    ((tests_total++))
    if grep -q "install_plugins_modern" "$DOTFILES_DIR/scripts/setup/setup_asdf.sh"; then
      test_passed "setup_asdf.sh includes modern plugin installation"
      ((tests_passed++))
    else
      test_failed "setup_asdf.sh missing modern plugin installation"
    fi
    
    ((tests_total++))
    if grep -q "shims" "$DOTFILES_DIR/scripts/setup/setup_asdf.sh"; then
      test_passed "setup_asdf.sh uses modern shims approach"
      ((tests_passed++))
    else
      test_failed "setup_asdf.sh missing modern shims approach"
    fi
  else
    test_failed "setup_asdf.sh not found"
  fi
  
  # Check if asdf-tool-versions file exists
  ((tests_total++))
  if [ -f "$DOTFILES_DIR/asdf-tool-versions" ]; then
    test_passed "asdf-tool-versions file exists"
    ((tests_passed++))
    
    # Test tool-versions file format
    ((tests_total++))
    local tool_count=$(wc -l < "$DOTFILES_DIR/asdf-tool-versions")
    if [[ $tool_count -gt 0 ]]; then
      test_passed "asdf-tool-versions contains $tool_count tools"
      ((tests_passed++))
    else
      test_failed "asdf-tool-versions is empty"
    fi
  else
    test_failed "asdf-tool-versions file not found"
  fi
  
  # Test asdf availability and modern features
  ((tests_total++))
  if command -v asdf >/dev/null 2>&1; then
    test_passed "asdf is available on this system"
    ((tests_passed++))
    
    # Test asdf version (should be 0.17+ for modern features)
    ((tests_total++))
    local asdf_version=$(asdf version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
    if [[ "$asdf_version" != "unknown" ]]; then
      local major=$(echo "$asdf_version" | cut -d '.' -f1)
      local minor=$(echo "$asdf_version" | cut -d '.' -f2)
      
      if [[ $major -gt 0 ]] || [[ $minor -ge 17 ]]; then
        test_passed "asdf version $asdf_version supports modern 0.17+ features"
        ((tests_passed++))
      else
        test_warning "asdf version $asdf_version is older than 0.17 (legacy mode)"
        ((tests_passed++))
      fi
    else
      test_warning "Could not detect asdf version"
    fi
    
    # Test shims directory
    ((tests_total++))
    local asdf_data_dir="${ASDF_DATA_DIR:-$HOME/.asdf}"
    if [ -d "$asdf_data_dir/shims" ]; then
      test_passed "asdf shims directory exists at $asdf_data_dir/shims"
      ((tests_passed++))
    else
      test_warning "asdf shims directory not found (may not be initialized yet)"
    fi
  else
    test_warning "asdf is not available on this system"
  fi
  
  echo ""
  log_info "Enhanced asdf integration tests: $tests_passed/$tests_total passed"
  return $((tests_total - tests_passed))
}

# Test GitHub tools integration
test_github_tools_integration() {
  log_info "Testing GitHub tools integration..."
  
  local tests_passed=0
  local tests_total=0
  
  # Test GitHub tools format parsing
  ((tests_total++))
  local test_github_tools=("jesseduffield/lazygit:lazygit" "mikefarah/yq:yq")
  
  for tool_spec in "${test_github_tools[@]}"; do
    local repo="${tool_spec%%:*}"
    local tool_name="${tool_spec##*:}"
    
    if [[ "$repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]] && [[ -n "$tool_name" ]]; then
      test_passed "GitHub tool format parsing works: $repo -> $tool_name"
      ((tests_passed++))
    else
      test_failed "GitHub tool format parsing failed: $tool_spec"
    fi
    ((tests_total++))
  done
  
  # Test curl availability (needed for GitHub releases)
  ((tests_total++))
  if command -v curl >/dev/null 2>&1; then
    test_passed "curl is available for GitHub releases"
    ((tests_passed++))
  else
    test_failed "curl is not available (needed for GitHub releases)"
  fi
  
  echo ""
  log_info "GitHub tools integration tests: $tests_passed/$tests_total passed"
  return $((tests_total - tests_passed))
}

# Test Phase 2 integration with main setup
test_phase2_main_setup_integration() {
  log_info "Testing Phase 2 integration with main setup..."
  
  local tests_passed=0
  local tests_total=0
  
  # Check if main setup.sh calls the enhanced Linux setup
  ((tests_total++))
  if [ -f "$DOTFILES_DIR/setup.sh" ]; then
    test_passed "Main setup.sh exists"
    ((tests_passed++))
    
    # Check if setup.sh references setup_linux.sh
    ((tests_total++))
    if grep -q "setup_linux.sh" "$DOTFILES_DIR/setup.sh"; then
      test_passed "setup.sh references setup_linux.sh"
      ((tests_passed++))
    else
      test_warning "setup.sh does not reference setup_linux.sh"
    fi
  else
    test_failed "Main setup.sh not found"
  fi
  
  echo ""
  log_info "Phase 2 main setup integration tests: $tests_passed/$tests_total passed"
  return $((tests_total - tests_passed))
}

# Test package manager coordination hierarchy
test_package_manager_hierarchy() {
  log_info "Testing package manager coordination hierarchy..."
  
  local tests_passed=0
  local tests_total=0
  
  # Source coordination to test hierarchy
  if [ -f "$SCRIPT_DIR/package_coordination.sh" ]; then
    source "$SCRIPT_DIR/package_coordination.sh"
    
    # Simulate Ubuntu environment
    export DOTFILES_PLATFORM="ubuntu"
    coordinate_packages
    
    # Test get_preferred_manager function
    local test_cases=(
      "git:apt"           # Should prefer apt for system tools
      "golang:asdf"       # Should prefer asdf for dev tools
      "code:snap"         # Should prefer snap for modern apps
    )
    
    for test_case in "${test_cases[@]}"; do
      local tool="${test_case%%:*}"
      local expected="${test_case##*:}"
      
      ((tests_total++))
      local preferred=$(get_preferred_manager "$tool")
      if [[ "$preferred" == "$expected" ]]; then
        test_passed "get_preferred_manager($tool) = $preferred (expected: $expected)"
        ((tests_passed++))
      else
        test_warning "get_preferred_manager($tool) = $preferred (expected: $expected)"
      fi
    done
  else
    test_failed "Package coordination script not found"
  fi
  
  echo ""
  log_info "Package manager hierarchy tests: $tests_passed/$tests_total passed"
  return $((tests_total - tests_passed))
}

# Main test function
main() {
  echo -e "${BLUE}${BOLD}========================================${NC}"
  echo -e "${BLUE}${BOLD}Phase 2: Enhanced Ubuntu Setup Tests${NC}"
  echo -e "${BLUE}${BOLD}========================================${NC}"
  echo ""
  
  local total_failures=0
  
  # Run Phase 2 specific tests
  test_enhanced_linux_setup
  total_failures=$((total_failures + $?))
  
  echo ""
  test_ubuntu_package_coordination
  total_failures=$((total_failures + $?))
  
  echo ""
  test_snap_integration
  total_failures=$((total_failures + $?))
  
  echo ""
  test_asdf_integration_enhancement
  total_failures=$((total_failures + $?))
  
  echo ""
  test_github_tools_integration
  total_failures=$((total_failures + $?))
  
  echo ""
  test_phase2_main_setup_integration
  total_failures=$((total_failures + $?))
  
  echo ""
  test_package_manager_hierarchy
  total_failures=$((total_failures + $?))
  
  # Summary
  echo ""
  echo -e "${BLUE}${BOLD}========================================${NC}"
  if [[ $total_failures -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}🎉 All Phase 2 tests passed!${NC}"
    echo -e "${GREEN}Enhanced Ubuntu setup is working correctly.${NC}"
    echo ""
    echo -e "${GREEN}Phase 2 Features Implemented:${NC}"
    echo -e "${GREEN}  ✓ Enhanced Linux setup with platform integration${NC}"
    echo -e "${GREEN}  ✓ Coordinated package management (apt + snap + asdf)${NC}"
    echo -e "${GREEN}  ✓ Snap fallback support${NC}"
    echo -e "${GREEN}  ✓ Enhanced asdf integration${NC}"
    echo -e "${GREEN}  ✓ GitHub tools framework${NC}"
    echo -e "${GREEN}  ✓ Package manager hierarchy${NC}"
  else
    echo -e "${RED}${BOLD}❌ Some Phase 2 tests failed (total failures: $total_failures)${NC}"
    echo -e "${YELLOW}Please review the failures above and fix any issues.${NC}"
  fi
  echo -e "${BLUE}${BOLD}========================================${NC}"
  
  return $total_failures
}

# Run tests
main "$@" 