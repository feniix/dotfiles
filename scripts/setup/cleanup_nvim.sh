#!/bin/bash
#
# Cleanup script for Neovim configuration
# This removes symlinks and restores backed up configurations if present

set -e

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "Cleaning up Neovim configuration..."

# Check if nvim directory exists and is a symlink
if [ -L "$XDG_CONFIG_HOME/nvim" ]; then
  echo "Removing nvim symlink..."
  rm "$XDG_CONFIG_HOME/nvim"
  
  # Find most recent backup and restore it if exists
  latest_backup=$(find "$XDG_CONFIG_HOME" -maxdepth 1 -name "nvim.bak.*" | sort -r | head -n 1)
  
  if [ -n "$latest_backup" ]; then
    echo "Restoring backup from $latest_backup..."
    mv "$latest_backup" "$XDG_CONFIG_HOME/nvim"
    echo "Backup restored successfully."
  else
    echo "No backup found. Creating fresh nvim directory..."
    mkdir -p "$XDG_CONFIG_HOME/nvim"
  fi
elif [ -d "$XDG_CONFIG_HOME/nvim" ]; then
  echo "nvim directory exists but is not a symlink. No cleanup needed."
else
  echo "No nvim configuration found. Nothing to clean up."
fi

echo "Neovim cleanup completed!" 