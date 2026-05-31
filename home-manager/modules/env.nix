{ config, dotfilesDir, ... }:

{
  xdg.enable = true;

  # Static env vars. Set in HM's session-vars script which zsh sources on login.
  home.sessionVariables = {
    EDITOR = "nvim";

    # XDG-redirected tool state (matches dotfiles/zshenv)
    AWS_CLI_HISTORY_FILE = "${config.xdg.dataHome}/aws/history";
    AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
    AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
    AWS_WEB_IDENTITY_TOKEN_FILE = "${config.xdg.dataHome}/aws/token";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    CURLOPT_COOKIEFILE = "${config.xdg.dataHome}/curl/cookies";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    GOPATH = "${config.xdg.dataHome}/go";
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
    INPUTRC = "${config.xdg.configHome}/readline/inputrc";
    KUBECONFIG = "${config.xdg.configHome}/kube/config";
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/repl_history";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
    SCREENRC = "${config.xdg.configHome}/screen/screenrc";
    TF_PLUGIN_CACHE_DIR = "${config.home.homeDirectory}/.terraform.d/plugin-cache";

    # Locale
    LANG = "en_US.UTF-8";
    LC_ADDRESS = "en_US.UTF-8";
    LC_COLLATE = "en_US.UTF-8";
    LC_CTYPE = "UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MESSAGES = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";

    # JVM
    JAVA_TOOL_OPTIONS = "-Dfile.encoding=UTF8 -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false";
    ANT_OPTS = "-Xmx4096m";
    MAVEN_OPTS = "-Xmx4096m";
    GRADLE_OPTS = "-Xmx4096m -Xms2024m";

    # AWS
    AWS_PAGER = "";
    AWS_SDK_LOAD_CONFIG = "1";

    # GCP/k8s
    USE_GKE_GCLOUD_AUTH_PLUGIN = "True";

    # Homebrew
    HOMEBREW_BREWFILE = "${dotfilesDir}/Brewfile";
    HOMEBREW_NO_ENV_HINTS = "1";
    HOMEBREW_NO_ANALYTICS = "1";
    HOMEBREW_AUTOREMOVE = "1";
    HOMEBREW_NO_INSTALL_UPGRADE = "1";

    # Personal
    NOTION_MCP_AUTH_FILE = "${config.home.homeDirectory}/.config/pi/secrets/notion-mcp-auth.json";

    # Skip OMZ's insecure-completion-dir audit. /opt/homebrew/share is
    # group-writable by Homebrew design (admin group), which triggers the
    # warning on every new shell. Must be the string "true" — OMZ does
    # `[[ $ZSH_DISABLE_COMPFIX != true ]]`. We already run compinit ourselves.
    ZSH_DISABLE_COMPFIX = "true";
  };
}
