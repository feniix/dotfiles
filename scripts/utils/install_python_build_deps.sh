#!/bin/bash
#
# Install Python Build Dependencies for Ubuntu
# This script installs the necessary development libraries for building Python from source

set -e

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

# Check if running on Ubuntu/Debian
if ! command -v apt >/dev/null 2>&1; then
  log_error "This script is for Ubuntu/Debian systems with apt package manager"
  exit 1
fi

log_info "🐍 Installing Python build dependencies for Ubuntu..."

# Python build dependencies
PYTHON_BUILD_DEPS=(
  # Core build tools
  "build-essential"
  "cmake"
  "autoconf"
  "automake"
  
  # Essential libraries
  "libssl-dev"          # SSL/TLS support
  "libreadline-dev"     # Readline support
  "libsqlite3-dev"      # SQLite support
  "zlib1g-dev"          # Compression support
  
  # Python-specific dependencies
  "libffi-dev"          # Foreign Function Interface
  "libbz2-dev"          # Bzip2 compression
  "liblzma-dev"         # LZMA compression
  "libncurses5-dev"     # Terminal handling
  "libncursesw5-dev"    # Wide character terminal handling
  "libmpdec-dev"        # Decimal arithmetic (fixes _decimal module)
  "libexpat1-dev"       # XML parsing
  "tk-dev"              # Tkinter GUI support
  "libgdbm-dev"         # GNU database manager
  "libnss3-dev"         # Network Security Services
  
  # Additional useful libraries
  "uuid-dev"            # UUID generation
  "libdb-dev"           # Berkeley DB
)

log_info "The following packages will be installed:"
for pkg in "${PYTHON_BUILD_DEPS[@]}"; do
  echo "  • $pkg"
done

echo ""
read -p "Proceed with installation? [y/N] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  log_info "Installation cancelled."
  exit 0
fi

# Update package list
log_info "Updating package list..."
sudo apt update

# Install packages
log_info "Installing Python build dependencies..."
installed_count=0
failed_packages=()

for pkg in "${PYTHON_BUILD_DEPS[@]}"; do
  log_info "Installing $pkg..."
  if sudo apt install -y "$pkg"; then
    ((installed_count++))
    log_success "✓ $pkg installed"
  else
    failed_packages+=("$pkg")
    log_warning "✗ Failed to install $pkg"
  fi
done

echo ""
log_success "Installation complete: $installed_count/${#PYTHON_BUILD_DEPS[@]} packages installed"

if [[ ${#failed_packages[@]} -gt 0 ]]; then
  log_warning "Failed packages: ${failed_packages[*]}"
  echo ""
  log_info "You can try installing failed packages manually:"
  for pkg in "${failed_packages[@]}"; do
    echo "  sudo apt install $pkg"
  done
fi

echo ""
log_success "🎉 Python build dependencies installed!"
log_info "You can now try building Python again:"
log_info "  asdf install python 3.13.2"

# Show what was missing specifically for the _decimal module
echo ""
log_info "📋 Key dependency for _decimal module:"
log_info "  • libmpdec-dev: Provides the decimal arithmetic library"
log_info "    This should fix the '_decimal.cpython-313-x86_64-linux-gnu.so' error" 