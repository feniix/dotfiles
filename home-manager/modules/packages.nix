{ pkgs, ... }:

{
  home.packages = (with pkgs; [
    codex
    curl
    diff-so-fancy
    direnv
    eza
    fd
    fzf
    gh
    google-chrome
    iterm2
    jq
    neovim
    ripgrep
    tmux
    tree-sitter
    wget
  ]);
}
