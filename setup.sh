#!/bin/bash

set -e

DOTFILES_DIR="$HOME/dotfiles"

has() {
  type "$1" > /dev/null 2>&1
  return $?
}

if [ -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles already installed and still haven't made a update mode" 
    exit 1
fi

git clone --recursive https://github.com/feniix/dotfiles.git $DOTFILES_DIR
