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

if [ $? ]; then
  ln -s $DOTFILES_DIR/vimdir $HOME/.vim
  ln -s $DOTFILES_DIR/oh-my-zsh $HOME/.oh-my-zsh
  ln -sf $DOTFILES_DIR/vimrc $HOME/.vimrc
  ln -sf $DOTFILES_DIR/zshrc $HOME/.zshrc
  ln -sf $DOTFILES_DIR/gitconfig $HOME/.gitconfig
  ln -sf $DOTFILES_DIR/gitignore_global $HOME/.gitignore_global
fi
