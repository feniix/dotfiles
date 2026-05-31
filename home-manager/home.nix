{ pkgs, ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/env.nix
    ./modules/zsh.nix
    ./modules/git.nix
    ./modules/ssh.nix
    ./modules/mise.nix
    ./modules/files.nix
    ./modules/activation.nix
  ];

  home.username = "feniix";
  home.homeDirectory = "/Users/feniix";

  # Don't bump unless you've read the HM release notes.
  home.stateVersion = "26.05";
  home.enableNixpkgsReleaseCheck = false;

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [ "google-chrome" ];

  programs.home-manager.enable = true;
}
