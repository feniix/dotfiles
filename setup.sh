#!/bin/bash

set -e

DOTFILES_DIR="$HOME/dotfiles"

has() {
  type "$1" > /dev/null 2>&1
  return $?
}

if ! has "brew"; then
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
  brew doctor
fi

if ! has "git"; then
  brew install git
fi

if [ -d "$DOTFILES_DIR" ]; then
    exit 1
fi

if ! has "curl"; then
  if has "wget"; then
    # Emulate curl with wget
    curl() {
      ARGS="$* "
      ARGS=${ARGS/-s /-q }
      ARGS=${ARGS/-o /-O }
      wget $ARGS
    }
  fi
fi

