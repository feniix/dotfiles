#!/bin/bash
#
# GitHub integration setup script
# Configures GitHub CLI, git credentials, and SSH keys

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

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

# Check if Homebrew is installed
check_homebrew() {
  if ! command -v brew &> /dev/null; then
    log_error "Homebrew is not installed. Please install Homebrew first."
    log_info "Run the following command to install Homebrew:"
    log_info "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    return 1
  fi
  
  return 0
}

# Install GitHub CLI
install_github_cli() {
  log_info "Setting up GitHub CLI..."
  
  # Check if Homebrew is installed
  if ! check_homebrew; then
    log_warning "Skipping GitHub CLI installation."
    return 1
  fi
  
  # Check if GitHub CLI is already installed
  if command -v gh &> /dev/null; then
    log_info "GitHub CLI is already installed."
    
    # Check for updates
    log_info "Checking for GitHub CLI updates..."
    brew upgrade gh 2>/dev/null || true
  else
    # Install GitHub CLI
    log_info "Installing GitHub CLI..."
    brew install gh
    
    if [ $? -eq 0 ]; then
      log_success "GitHub CLI installed successfully."
    else
      log_error "Failed to install GitHub CLI."
      return 1
    fi
  fi
  
  # Verify GitHub CLI installation
  if command -v gh &> /dev/null; then
    log_success "GitHub CLI is ready to use."
    
    # Show version information
    gh_version=$(gh --version | head -n 1)
    log_info "Installed version: $gh_version"
    
    return 0
  else
    log_error "GitHub CLI installation verification failed."
    return 1
  fi
}

# Setup GitHub authentication
setup_github_auth() {
  log_info "Setting up GitHub authentication..."
  
  # Check if GitHub CLI is installed
  if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI is not installed. Cannot set up authentication."
    return 1
  fi
  
  # Check if already authenticated
  if gh auth status &>/dev/null; then
    log_info "Already authenticated with GitHub."
    
    # Display current authentication status
    gh auth status
    
    # Ask if user wants to login again
    read -p "Do you want to login again? [y/N] " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log_info "Keeping existing GitHub authentication."
      return 0
    fi
  fi
  
  # Authenticate with GitHub
  log_info "Authenticating with GitHub..."
  log_info "Choose your preferred authentication method when prompted."
  
  gh auth login
  
  if [ $? -eq 0 ]; then
    log_success "GitHub authentication completed successfully."
    return 0
  else
    log_error "GitHub authentication failed."
    return 1
  fi
}

# Setup Git credentials
setup_git_credentials() {
  log_info "Setting up Git credentials..."
  
  # Check if git credential manager is configured
  if git config --global credential.helper >/dev/null 2>&1; then
    current_helper=$(git config --global credential.helper)
    log_info "Current credential helper: $current_helper"
  else
    log_info "No global credential helper configured."
  fi
  
  # Set up credential helper based on the OS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # Use macOS Keychain
    git config --global credential.helper osxkeychain
    log_success "Set up macOS Keychain as Git credential helper."
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Use libsecret if available, otherwise use cache
    if command -v git-credential-libsecret &> /dev/null; then
      git config --global credential.helper libsecret
      log_success "Set up libsecret as Git credential helper."
    else
      # Check if libsecret is available to install
      if command -v apt-get &> /dev/null; then
        log_info "libsecret is not installed. You may want to install it for better credential storage:"
        log_info "  sudo apt-get install libsecret-1-0 libsecret-1-dev"
        log_info "  cd /usr/share/doc/git/contrib/credential/libsecret && sudo make"
      fi
      
      # Set cache as fallback
      git config --global credential.helper 'cache --timeout=3600'
      log_success "Set up cache as Git credential helper (1 hour timeout)."
    fi
  else
    log_warning "Unsupported OS. Using basic cache credential helper."
    git config --global credential.helper 'cache --timeout=3600'
  fi
  
  # Configure git user info if not already set
  if [ -z "$(git config --global user.name)" ]; then
    log_info "Git user name not set. Let's configure it."
    read -p "Enter your name: " name
    git config --global user.name "$name"
  fi
  
  if [ -z "$(git config --global user.email)" ]; then
    log_info "Git email not set. Let's configure it."
    read -p "Enter your email: " email
    git config --global user.email "$email"
  fi
  
  log_success "Git credentials setup completed."
}

# Generate and setup SSH keys for GitHub
setup_ssh_keys() {
  log_info "Setting up SSH keys for GitHub..."
  
  # Create SSH directory with correct permissions
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  
  # Check if SSH key already exists
  if [ -f "$HOME/.ssh/id_ed25519" ]; then
    log_info "SSH key already exists at $HOME/.ssh/id_ed25519"
    
    # Ask if user wants to generate a new key
    read -p "Do you want to generate a new SSH key? [y/N] " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log_info "Using existing SSH key."
      return 0
    fi
  fi
  
  # Generate a new SSH key
  log_info "Generating a new SSH key..."
  read -p "Enter your email for the SSH key: " email
  
  ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519"
  
  if [ $? -eq 0 ]; then
    log_success "SSH key generated successfully."
    
    # Start ssh-agent and add the key
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_ed25519"
    
    # Copy the key to clipboard if available
    if command -v pbcopy &> /dev/null; then
      pbcopy < "$HOME/.ssh/id_ed25519.pub"
      log_success "Public key copied to clipboard."
    elif command -v xclip &> /dev/null; then
      xclip -selection clipboard < "$HOME/.ssh/id_ed25519.pub"
      log_success "Public key copied to clipboard."
    else
      log_info "Public key is available at: $HOME/.ssh/id_ed25519.pub"
      echo "---------- BEGIN SSH PUBLIC KEY ----------"
      cat "$HOME/.ssh/id_ed25519.pub"
      echo "----------- END SSH PUBLIC KEY -----------"
    fi
    
    # Add key to GitHub if CLI is available
    if command -v gh &> /dev/null; then
      log_info "Would you like to add this key to your GitHub account?"
      read -p "Add key to GitHub? [y/N] " -n 1 -r
      echo
      
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Get the key title
        hostname=$(hostname -s 2>/dev/null || echo "unknown-host")
        read -p "Enter a title for this SSH key [${hostname}-$(date '+%Y-%m-%d')]: " key_title
        key_title=${key_title:-"${hostname}-$(date '+%Y-%m-%d')"}
        
        # Add the key to GitHub
        log_info "Adding SSH key to GitHub..."
        
        gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$key_title"
        
        if [ $? -eq 0 ]; then
          log_success "SSH key added to GitHub successfully."
        else
          log_error "Failed to add SSH key to GitHub."
          log_info "Please add the key manually at https://github.com/settings/keys"
        fi
      else
        log_info "Skipping adding key to GitHub. You can add it manually at https://github.com/settings/keys"
      fi
    else
      log_info "GitHub CLI not available. Please add your SSH key to GitHub manually:"
      log_info "1. Go to https://github.com/settings/keys"
      log_info "2. Click 'New SSH key'"
      log_info "3. Add a title and paste your key"
    fi
    
    return 0
  else
    log_error "Failed to generate SSH key."
    return 1
  fi
}

# Configure GitHub CLI settings
configure_github_cli() {
  log_info "Configuring GitHub CLI settings..."
  
  # Check if GitHub CLI is installed
  if ! command -v gh &> /dev/null; then
    log_warning "GitHub CLI not installed. Skipping configuration."
    return 1
  fi
  
  # Set preferred editor
  if command -v nvim &> /dev/null; then
    gh config set editor nvim
  elif command -v vim &> /dev/null; then
    gh config set editor vim
  fi
  
  # Set preferred browser (optional)
  # gh config set browser "open %s"
  
  # Set color scheme to auto
  gh config set pager disabled
  
  # Display configuration
  log_info "GitHub CLI configuration:"
  gh config list
  
  log_success "GitHub CLI configured successfully."
}

# Main function
main() {
  log_info "Starting GitHub integration setup..."
  
  # Install GitHub CLI
  install_github_cli
  
  # Configure Git credentials
  setup_git_credentials
  
  # Setup SSH keys
  setup_ssh_keys
  
  # Setup GitHub authentication
  setup_github_auth
  
  # Configure GitHub CLI
  configure_github_cli
  
  log_success "GitHub integration setup completed successfully!"
}

# Execute main function
main 