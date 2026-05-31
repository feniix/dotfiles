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
    globalConfig = {
      settings = {
        all_compile = false;
        experimental = true;
      };
      tools = {
        bun = "1.3.14";
        node = "24.16.0";
        usage = "latest";
      };
    };
  };
}
