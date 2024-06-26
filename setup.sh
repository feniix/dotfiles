#!/bin/bash

set -e

DOTFILES_DIR="$HOME/dotfiles"

has() {
  type "$1" > /dev/null 2>&1
  return $?
}

if [ -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles already installed and still haven't made an update mode" 
    exit 1
fi

git clone --recursive https://github.com/feniix/dotfiles.git "$DOTFILES_DIR"
if [ $? ]; then
  ln -s "$DOTFILES_DIR/vimdir" "$HOME/.vim"
  ln -s "$DOTFILES_DIR/oh-my-zsh" "$HOME/.oh-my-zsh"
  ln -s "$DOTFILES_DIR/sbin" "$HOME/sbin"
  ln -sf "$DOTFILES_DIR/vimrc" "$HOME/.vimrc"
  ln -sf "$DOTFILES_DIR/aprc" "$HOME/.aprc"
  ln -sf "$DOTFILES_DIR/pryrc" "$HOME/.pryrc"
  ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
  ln -sf "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
  ln -sf "$DOTFILES_DIR/gitignore_global" "$HOME/.gitignore_global"
  ln -sf "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
  cp "$DOTFILES_DIR/fonts/*.ttf" "$HOME/Library/Fonts/"
  cp "$DOTFILES_DIR/iterm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/"
  echo "For iterm2 preferences to take effect the OS needs to be restarted"
  echo "Applying saner defaults to OSX, you will be asked for your password"
  sh "$DOTFILES_DIR/osx-defaults"
fi
