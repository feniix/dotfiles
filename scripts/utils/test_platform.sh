#!/bin/bash
#
# Platform Testing Script
# Tests the platform detection and package coordination functionality

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
  echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[TEST]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[TEST]${NC} $1"
}

log_error() {
  echo -e "${RED}[TEST]${NC} $1"
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

# Test platform detection
test_platform_detection() {
  log_info "Testing platform detection..."
  
  # Source the platform detection script
  if [ -f "$SCRIPT_DIR/platform_detection.sh" ]; then
    source "$SCRIPT_DIR/platform_detection.sh"
    
    # Run detection
    if detect_platform; then
      test_passed "Platform detection executed successfully"
      
      # Check required variables are set
      local tests_passed=0
      local tests_total=0
      
      # Test required variables
      variables=(
        "DOTFILES_PLATFORM"
        "DOTFILES_ARCH"
        "PRIMARY_PKG_MANAGER"
        "XDG_CONFIG_HOME"
        "XDG_DATA_HOME"
        "HOMEBREW_AVAILABLE"
        "GIT_AVAILABLE"
        "CURL_AVAILABLE"
      )
      
      for var in "${variables[@]}"; do
        ((tests_total++))
        if [[ -n "${!var}" ]]; then
          test_passed "Variable $var is set: ${!var}"
          ((tests_passed++))
        else
          test_failed "Variable $var is not set"
        fi
      done
      
      # Platform-specific tests
      ((tests_total++))
      case "$DOTFILES_PLATFORM" in
        "macos")
          if [[ "$PRIMARY_PKG_MANAGER" == "brew" ]]; then
            test_passed "macOS has correct primary package manager: $PRIMARY_PKG_MANAGER"
            ((tests_passed++))
          else
            test_failed "macOS should have 'brew' as primary package manager, got: $PRIMARY_PKG_MANAGER"
          fi
          ;;
        "ubuntu"|"linux")
          if [[ "$PRIMARY_PKG_MANAGER" == "apt" ]]; then
            test_passed "Linux/Ubuntu has correct primary package manager: $PRIMARY_PKG_MANAGER"
            ((tests_passed++))
          else
            test_failed "Linux/Ubuntu should have 'apt' as primary package manager, got: $PRIMARY_PKG_MANAGER"
          fi
          ;;
        *)
          test_warning "Unknown platform: $DOTFILES_PLATFORM"
          ;;
      esac
      
      echo ""
      log_info "Platform detection tests: $tests_passed/$tests_total passed"
      return $((tests_total - tests_passed))
    else
      test_failed "Platform detection failed to execute"
      return 1
    fi
  else
    test_failed "Platform detection script not found at $SCRIPT_DIR/platform_detection.sh"
    return 1
  fi
}

# Test package coordination
test_package_coordination() {
  log_info "Testing package coordination..."
  
     # Source the package coordination script
  if [ -f "$SCRIPT_DIR/package_coordination.sh" ]; then
    source "$SCRIPT_DIR/package_coordination.sh"
    
    # Run coordination (requires platform detection first)
    if coordinate_packages; then
      # Source again to get the exported arrays
      source "$SCRIPT_DIR/package_coordination.sh"
      test_passed "Package coordination executed successfully"
      
      local tests_passed=0
      local tests_total=0
      
      # Test that coordination is properly set up
      case "$DOTFILES_PLATFORM" in
        "macos")
          ((tests_total++))
          if [[ -n "$BREWFILE_PATH" ]] && [[ -f "$BREWFILE_PATH" ]]; then
            test_passed "Brewfile path is set and file exists: $BREWFILE_PATH"
            ((tests_passed++))
          else
            test_failed "Brewfile path not set or file doesn't exist: $BREWFILE_PATH"
          fi
          
          ((tests_total++))
          if [[ -n "${ASDF_TOOLS[*]}" ]]; then
            test_passed "ASDF_TOOLS array is defined (${#ASDF_TOOLS[@]} tools)"
            ((tests_passed++))
          else
            test_failed "ASDF_TOOLS array is not defined"
          fi
          ;;
        "ubuntu"|"linux")
          ((tests_total++))
          if [[ -n "${APT_PACKAGES[*]}" ]]; then
            test_passed "APT_PACKAGES array is defined (${#APT_PACKAGES[@]} packages)"
            ((tests_passed++))
          else
            test_failed "APT_PACKAGES array is not defined"
          fi
          
          ((tests_total++))
          if [[ -n "${ASDF_TOOLS[*]}" ]]; then
            test_passed "ASDF_TOOLS array is defined (${#ASDF_TOOLS[@]} tools)"
            ((tests_passed++))
          else
            test_failed "ASDF_TOOLS array is not defined"
          fi
          ;;
      esac
      
      # Test get_preferred_manager function
      ((tests_total++))
      local test_tool="git"
      local preferred_manager
      preferred_manager=$(get_preferred_manager "$test_tool")
      if [[ "$preferred_manager" != "unknown" ]]; then
        test_passed "get_preferred_manager works for '$test_tool': $preferred_manager"
        ((tests_passed++))
      else
        test_failed "get_preferred_manager failed for '$test_tool'"
      fi
      
      echo ""
      log_info "Package coordination tests: $tests_passed/$tests_total passed"
      return $((tests_total - tests_passed))
    else
      test_failed "Package coordination failed to execute"
      return 1
    fi
  else
    test_failed "Package coordination script not found at $SCRIPT_DIR/package_coordination.sh"
    return 1
  fi
}

# Test integration with main setup script
test_setup_integration() {
  log_info "Testing integration with main setup script..."
  
  local tests_passed=0
  local tests_total=0
  
  # Check if setup.sh exists
  ((tests_total++))
  if [ -f "$DOTFILES_DIR/setup.sh" ]; then
    test_passed "Main setup.sh script exists"
    ((tests_passed++))
    
    # Check if setup.sh references our new scripts
    ((tests_total++))
    if grep -q "platform_detection.sh" "$DOTFILES_DIR/setup.sh"; then
      test_passed "setup.sh references platform_detection.sh"
      ((tests_passed++))
    else
      test_failed "setup.sh does not reference platform_detection.sh"
    fi
    
    ((tests_total++))
    if grep -q "package_coordination.sh" "$DOTFILES_DIR/setup.sh"; then
      test_passed "setup.sh references package_coordination.sh"
      ((tests_passed++))
    else
      test_failed "setup.sh does not reference package_coordination.sh"
    fi
  else
    test_failed "Main setup.sh script not found"
  fi
  
  echo ""
  log_info "Setup integration tests: $tests_passed/$tests_total passed"
  return $((tests_total - tests_passed))
}

# Main test function
main() {
  echo -e "${BLUE}${BOLD}========================================${NC}"
  echo -e "${BLUE}${BOLD}Platform Detection & Coordination Tests${NC}"
  echo -e "${BLUE}${BOLD}========================================${NC}"
  echo ""
  
  local total_failures=0
  
  # Run tests
  test_platform_detection
  total_failures=$((total_failures + $?))
  
  echo ""
  test_package_coordination
  total_failures=$((total_failures + $?))
  
  echo ""
  test_setup_integration
  total_failures=$((total_failures + $?))
  
  # Summary
  echo ""
  echo -e "${BLUE}${BOLD}========================================${NC}"
  if [[ $total_failures -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}🎉 All tests passed!${NC}"
    echo -e "${GREEN}Phase 1 implementation is working correctly.${NC}"
  else
    echo -e "${RED}${BOLD}❌ Some tests failed (total failures: $total_failures)${NC}"
    echo -e "${YELLOW}Please review the failures above and fix any issues.${NC}"
  fi
  echo -e "${BLUE}${BOLD}========================================${NC}"
  
  return $total_failures
}

# Run tests
main 