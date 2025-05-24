#!/bin/bash
#
# Dotfiles Validation Script
# Tests core functionality and consistency after fixes

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

test_passed=0
test_failed=0

run_test() {
  local test_name="$1"
  local test_command="$2"
  
  log_info "Testing: $test_name"
  
  if eval "$test_command" > /dev/null 2>&1; then
    echo "  ✅ PASS: $test_name"
    test_passed=$((test_passed + 1))
  else
    echo "  ❌ FAIL: $test_name"
    test_failed=$((test_failed + 1))
  fi
}

echo "🧪 Starting Dotfiles Validation..."
echo "=================================="

# Test 1: Repository Structure
log_info "1. Testing Repository Structure"
run_test "Main setup script exists" "[ -f '$SCRIPT_DIR/setup.sh' ]"
run_test "Scripts directory exists" "[ -d '$SCRIPT_DIR/scripts' ]"
run_test "Setup scripts directory exists" "[ -d '$SCRIPT_DIR/scripts/setup' ]"
run_test "Neovim scripts directory exists" "[ -d '$SCRIPT_DIR/scripts/nvim' ]"

# Test 2: Script Consistency
log_info "2. Testing Script Consistency"
setup_scripts_with_set_e=$(find "$SCRIPT_DIR/scripts/setup" -name "*.sh" -exec grep -l "set -e" {} \; 2>/dev/null | wc -l)
setup_scripts_total=$(find "$SCRIPT_DIR/scripts/setup" -name "*.sh" 2>/dev/null | wc -l)

if [ "$setup_scripts_with_set_e" -eq "$setup_scripts_total" ] && [ "$setup_scripts_total" -gt 0 ]; then
  echo "  ✅ PASS: All setup scripts have 'set -e'"
  test_passed=$((test_passed + 1))
else
  echo "  ❌ FAIL: Not all setup scripts have 'set -e' ($setup_scripts_with_set_e/$setup_scripts_total)"
  test_failed=$((test_failed + 1))
fi

setup_scripts_with_dotfiles_dir=$(find "$SCRIPT_DIR/scripts/setup" -name "*.sh" -exec grep -l "DOTFILES_DIR" {} \; 2>/dev/null | wc -l)

if [ "$setup_scripts_with_dotfiles_dir" -eq "$setup_scripts_total" ] && [ "$setup_scripts_total" -gt 0 ]; then
  echo "  ✅ PASS: All setup scripts use DOTFILES_DIR variable"
  test_passed=$((test_passed + 1))
else
  echo "  ❌ FAIL: Not all setup scripts use DOTFILES_DIR ($setup_scripts_with_dotfiles_dir/$setup_scripts_total)"
  test_failed=$((test_failed + 1))
fi

# Test 3: Key Scripts Executable
log_info "3. Testing Script Permissions"
run_test "Main setup script is executable" "[ -x '$SCRIPT_DIR/setup.sh' ]"
run_test "setup_macos.sh is executable" "[ -x '$SCRIPT_DIR/scripts/setup/setup_macos.sh' ]"
run_test "setup_zsh.sh is executable" "[ -x '$SCRIPT_DIR/scripts/setup/setup_zsh.sh' ]"
run_test "setup_homebrew.sh is executable" "[ -x '$SCRIPT_DIR/scripts/setup/setup_homebrew.sh' ]"

# Test 4: Configuration Files Exist
log_info "4. Testing Configuration Files"
run_test "zshrc exists" "[ -f '$SCRIPT_DIR/zshrc' ]"
run_test "zshenv exists" "[ -f '$SCRIPT_DIR/zshenv' ]"
run_test "Brewfile exists" "[ -f '$SCRIPT_DIR/Brewfile' ]"
run_test "Neovim init.lua exists" "[ -f '$SCRIPT_DIR/nvim/init.lua' ]"

# Test 5: XDG Environment Variables (if already sourced)
log_info "5. Testing XDG Environment Variables"
if [ -n "$XDG_CONFIG_HOME" ]; then
  echo "  ✅ PASS: XDG_CONFIG_HOME is set ($XDG_CONFIG_HOME)"
  test_passed=$((test_passed + 1))
else
  echo "  ⚠️  INFO: XDG_CONFIG_HOME not set (run 'source zshenv' first)"
fi

if [ -n "$XDG_DATA_HOME" ]; then
  echo "  ✅ PASS: XDG_DATA_HOME is set ($XDG_DATA_HOME)"
  test_passed=$((test_passed + 1))
else
  echo "  ⚠️  INFO: XDG_DATA_HOME not set (run 'source zshenv' first)"
fi

# Test 6: Symlinks (if they exist)
log_info "6. Testing Symlinks (if created)"
if [ -L "$HOME/.config/zsh/.zshrc" ]; then
  if [ -e "$HOME/.config/zsh/.zshrc" ]; then
    echo "  ✅ PASS: zshrc symlink exists and is valid"
    test_passed=$((test_passed + 1))
  else
    echo "  ❌ FAIL: zshrc symlink is broken"
    test_failed=$((test_failed + 1))
  fi
else
  echo "  ⚠️  INFO: zshrc symlink not created yet"
fi

if [ -L "$HOME/.config/git/config" ]; then
  if [ -e "$HOME/.config/git/config" ]; then
    echo "  ✅ PASS: git config symlink exists and is valid"
    test_passed=$((test_passed + 1))
  else
    echo "  ❌ FAIL: git config symlink is broken"
    test_failed=$((test_failed + 1))
  fi
else
  echo "  ⚠️  INFO: git config symlink not created yet"
fi

# Test 7: Syntax Check on Key Scripts
log_info "7. Testing Script Syntax"
run_test "setup.sh syntax is valid" "bash -n '$SCRIPT_DIR/setup.sh'"
run_test "setup_macos.sh syntax is valid" "bash -n '$SCRIPT_DIR/scripts/setup/setup_macos.sh'"
run_test "setup_zsh.sh syntax is valid" "bash -n '$SCRIPT_DIR/scripts/setup/setup_zsh.sh'"

# Test 8: Neovim Configuration Syntax
log_info "8. Testing Neovim Configuration"
if command -v nvim >/dev/null 2>&1; then
  run_test "Neovim configuration syntax is valid" "nvim --headless -c 'lua print(\"OK\")' -c 'quitall'"
else
  echo "  ⚠️  INFO: Neovim not installed, skipping config test"
fi

# Test 9: Log Function Consistency
log_info "9. Testing Log Function Consistency"
setup_scripts_with_log_functions=$(find "$SCRIPT_DIR/scripts/setup" -name "*.sh" -exec grep -l "log_info()" {} \; 2>/dev/null | wc -l)

if [ "$setup_scripts_with_log_functions" -eq "$setup_scripts_total" ] && [ "$setup_scripts_total" -gt 0 ]; then
  echo "  ✅ PASS: All setup scripts have standardized log functions"
  test_passed=$((test_passed + 1))
else
  echo "  ❌ FAIL: Not all setup scripts have log functions ($setup_scripts_with_log_functions/$setup_scripts_total)"
  test_failed=$((test_failed + 1))
fi

# Test 10: Check for Hardcoded Paths
log_info "10. Testing for Hardcoded Paths"
hardcoded_paths=$(grep -r "~/dotfiles" "$SCRIPT_DIR/scripts/setup/" 2>/dev/null | grep -v "DOTFILES_DIR" | wc -l)

if [ "$hardcoded_paths" -eq 0 ]; then
  echo "  ✅ PASS: No hardcoded ~/dotfiles paths in setup scripts"
  test_passed=$((test_passed + 1))
else
  echo "  ❌ FAIL: Found $hardcoded_paths hardcoded ~/dotfiles paths in setup scripts"
  test_failed=$((test_failed + 1))
fi

echo ""
echo "=================================="
echo "🏁 Validation Results:"
echo "   ✅ Passed: $test_passed tests"
echo "   ❌ Failed: $test_failed tests"

if [ $test_failed -eq 0 ]; then
  log_success "All critical tests passed! ✨"
  echo ""
  echo "📋 Next Steps:"
  echo "1. Run './setup.sh' to install the dotfiles"
  echo "2. Test individual components with scripts in scripts/setup/"
  echo "3. Restart your terminal to apply changes"
  echo "4. Run 'nvim' to test the Neovim configuration"
  exit 0
else
  log_error "Some tests failed. Please review and fix the issues."
  exit 1
fi