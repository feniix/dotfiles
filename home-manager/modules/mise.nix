{ ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    globalConfig = builtins.fromTOML (builtins.readFile ../../mise/config.toml);
  };
}
