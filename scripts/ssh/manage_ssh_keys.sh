#!/bin/bash
#
# Secure SSH Keys Management
# This script helps manage SSH keys securely outside of git
# It handles backing up, restoring, and checking permissions of SSH keys

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

# Default locations
SSH_DIR="$HOME/.ssh"
BACKUP_DIR="$HOME/.ssh_backup"
KEYS_LIST="id_rsa id_ed25519 id_ecdsa id_dsa"

# Make sure permissions are correct on SSH keys
fix_permissions() {
  log_info "Fixing permissions on SSH keys..."
  
  # Create SSH directory if it doesn't exist
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  
  # Fix permissions on each key file
  for key in $KEYS_LIST; do
    if [ -f "$SSH_DIR/$key" ]; then
      chmod 600 "$SSH_DIR/$key"
      log_success "Set permissions on $SSH_DIR/$key"
    fi
    
    if [ -f "$SSH_DIR/${key}.pub" ]; then
      chmod 644 "$SSH_DIR/${key}.pub"
      log_success "Set permissions on $SSH_DIR/${key}.pub"
    fi
  done
  
  # Set permissions for known_hosts and config
  for file in known_hosts config authorized_keys; do
    if [ -f "$SSH_DIR/$file" ]; then
      chmod 644 "$SSH_DIR/$file"
      log_success "Set permissions on $SSH_DIR/$file"
    fi
  done
  
  log_success "SSH permissions fixed"
}

# Backup SSH keys to a secure location
backup_keys() {
  local dest_dir=${1:-"$BACKUP_DIR"}
  
  log_info "Backing up SSH keys to $dest_dir..."
  
  # Create backup directory
  mkdir -p "$dest_dir"
  chmod 700 "$dest_dir"
  
  # Copy each key if it exists
  for key in $KEYS_LIST; do
    if [ -f "$SSH_DIR/$key" ]; then
      cp "$SSH_DIR/$key" "$dest_dir/"
      chmod 600 "$dest_dir/$key"
      log_success "Backed up $key"
    fi
    
    if [ -f "$SSH_DIR/${key}.pub" ]; then
      cp "$SSH_DIR/${key}.pub" "$dest_dir/"
      chmod 644 "$dest_dir/${key}.pub"
      log_success "Backed up ${key}.pub"
    fi
  done
  
  # Backup config if it exists
  if [ -f "$SSH_DIR/config" ]; then
    cp "$SSH_DIR/config" "$dest_dir/"
    log_success "Backed up SSH config"
  fi
  
  log_success "SSH keys backed up to $dest_dir"
  log_warning "Remember to keep this directory secure and consider encrypting it"
}

# Restore SSH keys from backup
restore_keys() {
  local source_dir=${1:-"$BACKUP_DIR"}
  
  if [ ! -d "$source_dir" ]; then
    log_error "Backup directory $source_dir does not exist"
    return 1
  fi
  
  log_info "Restoring SSH keys from $source_dir..."
  
  # Create SSH directory if it doesn't exist
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  
  # Restore each key if it exists in the backup
  for key in $KEYS_LIST; do
    if [ -f "$source_dir/$key" ]; then
      cp "$source_dir/$key" "$SSH_DIR/"
      chmod 600 "$SSH_DIR/$key"
      log_success "Restored $key"
    fi
    
    if [ -f "$source_dir/${key}.pub" ]; then
      cp "$source_dir/${key}.pub" "$SSH_DIR/"
      chmod 644 "$SSH_DIR/${key}.pub"
      log_success "Restored ${key}.pub"
    fi
  done
  
  # Restore config if it exists in the backup
  if [ -f "$source_dir/config" ]; then
    cp "$source_dir/config" "$SSH_DIR/"
    chmod 644 "$SSH_DIR/config"
    log_success "Restored SSH config"
  fi
  
  log_success "SSH keys restored from $source_dir"
}

# Print current SSH keys information
list_keys() {
  log_info "Listing current SSH keys:"
  
  local key_count=0
  
  for key in $KEYS_LIST; do
    if [ -f "$SSH_DIR/$key" ]; then
      local mod_time=$(stat -f "%Sm" "$SSH_DIR/$key" 2>/dev/null || stat -c "%y" "$SSH_DIR/$key")
      local perms=$(stat -f "%Sp" "$SSH_DIR/$key" 2>/dev/null || stat -c "%A" "$SSH_DIR/$key")
      echo "- $key ($perms, modified: $mod_time)"
      
      if [ -f "$SSH_DIR/${key}.pub" ]; then
        echo "  └─ Public key: ${key}.pub"
        echo "     $(head -1 "$SSH_DIR/${key}.pub" | cut -d ' ' -f 3)"
      fi
      
      key_count=$((key_count + 1))
    fi
  done
  
  if [ $key_count -eq 0 ]; then
    log_warning "No SSH keys found in $SSH_DIR"
  fi
}

# Check if keys have a passphrase
check_passphrases() {
  log_info "Checking if SSH keys have passphrases..."
  
  for key in $KEYS_LIST; do
    if [ -f "$SSH_DIR/$key" ]; then
      if ssh-keygen -y -P "" -f "$SSH_DIR/$key" >/dev/null 2>&1; then
        log_warning "$key is NOT protected with a passphrase"
        echo "  Consider adding a passphrase with: ssh-keygen -p -f $SSH_DIR/$key"
      else
        log_success "$key is protected with a passphrase"
      fi
    fi
  done
}

# Add passphrase to an existing key
add_passphrase() {
  local key_file=$1
  
  if [ -z "$key_file" ]; then
    log_error "No key file specified"
    echo "Usage: $0 add-passphrase <key_file>"
    return 1
  fi
  
  # Check if key exists
  if [ ! -f "$SSH_DIR/$key_file" ]; then
    log_error "Key file $SSH_DIR/$key_file does not exist"
    return 1
  fi
  
  log_info "Adding passphrase to $key_file..."
  
  # Create a backup of the key before modifying
  cp "$SSH_DIR/$key_file" "$SSH_DIR/${key_file}.bak"
  log_info "Backup created at $SSH_DIR/${key_file}.bak"
  
  # Add passphrase
  ssh-keygen -p -f "$SSH_DIR/$key_file"
  
  if [ $? -eq 0 ]; then
    log_success "Passphrase added to $key_file"
  else
    log_error "Failed to add passphrase to $key_file"
    log_info "Restoring from backup..."
    mv "$SSH_DIR/${key_file}.bak" "$SSH_DIR/$key_file"
    log_info "Original key restored"
    return 1
  fi
  
  # Remove backup if successful
  rm "$SSH_DIR/${key_file}.bak"
}

# Display help information
show_help() {
  echo "SSH Keys Management Utility"
  echo ""
  echo "Usage: $0 <command>"
  echo ""
  echo "Commands:"
  echo "  fix-permissions    Fix permissions on SSH keys"
  echo "  backup [dir]       Backup SSH keys to specified directory or default"
  echo "  restore [dir]      Restore SSH keys from specified directory or default"
  echo "  list               List current SSH keys"
  echo "  check-passphrases  Check if keys have passphrases"
  echo "  add-passphrase <key> Add a passphrase to an existing key"
  echo "  help               Display this help message"
  echo ""
  echo "Default backup directory: $BACKUP_DIR"
}

# Main function
main() {
  if [ $# -eq 0 ]; then
    show_help
    exit 0
  fi
  
  command=$1
  shift
  
  case $command in
    fix-permissions)
      fix_permissions
      ;;
    backup)
      backup_keys "$1"
      ;;
    restore)
      restore_keys "$1"
      ;;
    list)
      list_keys
      ;;
    check-passphrases)
      check_passphrases
      ;;
    add-passphrase)
      add_passphrase "$1"
      ;;
    help)
      show_help
      ;;
    *)
      log_error "Unknown command: $command"
      show_help
      exit 1
      ;;
  esac
}

# Run main function with provided arguments
main "$@" 