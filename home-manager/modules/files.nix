{ config, dotfilesDir, ... }:

# Live symlinks (not /nix/store copies) so edits in ~/dotfiles take effect
# immediately without needing a `home-manager switch`. The symlink chain is:
#   ~/.config/X  ->  /nix/store/...-home-manager-files/.config/X  ->  ~/dotfiles/X
let
  liveLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  xdg.configFile = {
    "zsh/.p10k.zsh".source           = liveLink "p10k.zsh";
    "git/ignore".source              = liveLink "gitignore_global";
    "git/allowed_signers".source     = liveLink "git_allowed_signers";
    "tmux/tmux.conf".source          = liveLink "tmux.conf";

    # Whole nvim tree — preserves :Lazy mutations to lazy-lock.json and lets
    # you edit init.lua / Lua modules directly in ~/dotfiles/nvim/.
    "nvim".source                    = liveLink "nvim";
  };

  # Small linter / editor configs sitting in $HOME
  home.file = {
    ".vimrc".source      = liveLink ".vimrc";
    ".pylintrc".source   = liveLink "pylintrc";
    ".luacheckrc".source = liveLink ".luacheckrc";
  };
}
