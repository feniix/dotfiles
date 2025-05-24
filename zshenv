# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"

# Create XDG runtime directory if it doesn't exist
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 0700 "$XDG_RUNTIME_DIR"
fi

# Set ZDOTDIR to respect XDG paths
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Traditional tools with XDG support
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export SCREENRC="$XDG_CONFIG_HOME/screen/screenrc"
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export GOPATH="$XDG_DATA_HOME/go"
export CARGO_HOME="$XDG_DATA_HOME/cargo"

# Create necessary directories (only if missing)
[ -d "$XDG_STATE_HOME/zsh" ] || mkdir -p "$XDG_STATE_HOME/zsh"
[ -d "$XDG_STATE_HOME/less" ] || mkdir -p "$XDG_STATE_HOME/less"
[ -d "$XDG_STATE_HOME/node" ] || mkdir -p "$XDG_STATE_HOME/node"
[ -d "$XDG_DATA_HOME/curl" ] || mkdir -p "$XDG_DATA_HOME/curl"

# Cleanup home directory by redirecting tool configs to XDG locations
export CURLOPT_COOKIEFILE="$XDG_DATA_HOME/curl/cookies"



# AWS CLI Configuration (additional settings)
export AWS_CLI_HISTORY_FILE="$XDG_DATA_HOME/aws/history"
export AWS_WEB_IDENTITY_TOKEN_FILE="$XDG_DATA_HOME/aws/token"
# Homebrew environment setup (prevent double-evaluation)
if [ -z "$HOMEBREW_PREFIX" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export ASDF_HASHICORP_SKIP_VERIFY=0
