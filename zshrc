# Path to your oh-my-zsh configuration.

# === PATH CONFIGURATION ===
# Reset PATH to ensure proper ordering
reset_path() {
  # Save important system paths that should be included but at lower priority
  local usr_local_bin="/usr/local/bin"
  local usr_bin="/usr/bin"
  local usr_sbin="/usr/sbin"
  local bin="/bin"
  local sbin="/sbin"

  # Add homebrew core utils next (highest priority after base homebrew)
  # Only add Homebrew GNU tool paths on macOS (Linux already has GNU tools)
  if command -v brew >/dev/null 2>&1 && [[ "$OSTYPE" == "darwin"* ]]; then
    local brew_prefix="$(brew --prefix)"
    export PATH="$PATH:$brew_prefix/opt/curl/bin"
    export PATH="$PATH:$brew_prefix/opt/make/libexec/gnubin"
    export PATH="$PATH:$brew_prefix/opt/gnu-getopt/bin"
    export PATH="$PATH:$brew_prefix/opt/gnu-tar/libexec/gnubin"
    export PATH="$PATH:$brew_prefix/opt/findutils/bin"
    export PATH="$PATH:$brew_prefix/opt/gawk/bin"
    export PATH="$PATH:$brew_prefix/opt/less/bin"
    export PATH="$PATH:$brew_prefix/opt/libpq/bin"
    export PATH="$PATH:$brew_prefix/opt/ssh-copy-id/bin"
  fi

  # Tool-specific paths
  export PATH="$PATH:${KREW_ROOT:-$HOME/.krew}/bin"
  export PATH="$PATH:$HOME/.linkerd2/bin"
  export PATH="$PATH:$HOME/.docker/bin"
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

  # Add user directories next
  export PATH="$PATH:$HOME/bin:$HOME/sbin:$HOME/.local/share/go/bin"

  # Add system paths at lowest priority
  export PATH="$PATH:$usr_local_bin:$usr_bin:$usr_sbin:$bin:$sbin"
}

# Initialize with proper ordering
reset_path

# Helper functions for PATH management
# Add to PATH only if directory exists (and only if not already in PATH)
prepend_path() {
  if [[ -d "$1" && ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}

append_path() {
  if [[ -d "$1" && ":$PATH:" != *":$1:"* ]]; then
    export PATH="$PATH:$1"
  fi
}

# Add to MANPATH only if directory exists
prepend_manpath() {
  if [[ -d "$1" && ":$MANPATH:" != *":$1:"* ]]; then
    export MANPATH="$1:$MANPATH"
  fi
}

append_manpath() {
  if [[ -d "$1" && ":$MANPATH:" != *":$1:"* ]]; then
    export MANPATH="$MANPATH:$1"
  fi
}

# Debug PATH and MANPATH
debug_path() {
  echo "=== PATH ==="
  echo $PATH | tr ':' '\n' | nl
  echo ""
  echo "=== MANPATH ==="
  echo $MANPATH | tr ':' '\n' | nl
  echo ""

  # Check for non-existent directories in PATH
  echo "=== Non-existent directories in PATH ==="
  for p in $(echo $PATH | tr ':' '\n'); do
    if [[ ! -d "$p" ]]; then
      echo "MISSING: $p"
    fi
  done
}

# === COMPLETION SETUP ===
# Set up completions once, efficiently
if type brew &>/dev/null; then
  local brew_prefix="$(brew --prefix)"
  FPATH="$brew_prefix/share/zsh/site-functions:$brew_prefix/share/zsh-completions:$FPATH"
fi

# Skip global compinit in oh-my-zsh, we'll call it once efficiently
skip_global_compinit=1

# Load completions without compiling
autoload -Uz compinit
  # Only rebuild completion cache once a week, without compiling
  # Platform-aware stat command for checking .zcompdump modification time
  local zcompdump_file="${ZDOTDIR:-$HOME}/.zcompdump"
  local current_day=$(date +'%j')
  local file_day=""
  
  if [[ -f "$zcompdump_file" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS/BSD stat
      file_day=$(/usr/bin/stat -f '%Sm' -t '%j' "$zcompdump_file" 2>/dev/null)
    else
      # Linux/GNU stat
      file_day=$(stat -c '%Y' "$zcompdump_file" 2>/dev/null | xargs -I {} date -d @{} +'%j')
    fi
  fi
  
  if [[ "$current_day" != "$file_day" ]]; then
    compinit -D
  else
    compinit -D -C
  fi

  # Completion caching
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path ~/.zsh/cache

  # Better completion options
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# === OH-MY-ZSH CONFIGURATION ===
export ZSH=$HOME/.oh-my-zsh

# Theme configuration
ZSH_THEME=""  # Disabling Oh-My-Zsh themes as we're using Powerlevel10k via Homebrew

# === PERFORMANCE OPTIMIZATIONS ===
# Disable oh-my-zsh automatic update checks
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"

# Reduce oh-my-zsh startup time
DISABLE_MAGIC_FUNCTIONS="true"
COMPLETION_WAITING_DOTS="false"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# === PLUGIN CONFIGURATION ===
# Core plugins - always loaded
plugins=(
  # Essentials
  history-substring-search
  colored-man-pages
  command-not-found

  # Movement and navigation
  last-working-dir

  # Shell utilities
  sudo
  gnu-utils

  # Git and version control
  git
  git-extras

  # Development tools
  python
  pip
  rust

  # Container & cloud
  docker
  docker-compose
  kubectl
  aws

  # Build tools
  ant
  gradle
  mvn
)

# Add platform-specific or optional plugins
# Function to safely add plugins that might not be installed
add_plugin_if_exists() {
  local plugin_name="$1"
  local install_cmd="$2"
  
  if [[ -d "$ZSH/custom/plugins/$plugin_name" ]] || [[ -d "$ZSH/plugins/$plugin_name" ]]; then
    plugins+=(${plugin_name})
  else
    echo "Note: $plugin_name plugin not found." >&2
    if [[ -n "$install_cmd" ]]; then
      echo "  Install with: $install_cmd" >&2
    fi
  fi
}

# zsh-completions: External plugin for additional completions
add_plugin_if_exists "zsh-completions" "git clone https://github.com/zsh-users/zsh-completions \${ZSH_CUSTOM:-\$ZSH/custom}/plugins/zsh-completions"

# zsh-syntax-highlighting: External plugin for syntax highlighting (optional)
add_plugin_if_exists "zsh-syntax-highlighting" "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-\$ZSH/custom}/plugins/zsh-syntax-highlighting"

# zsh-autosuggestions: External plugin for autosuggestions (optional)
add_plugin_if_exists "zsh-autosuggestions" "git clone https://github.com/zsh-users/zsh-autosuggestions \${ZSH_CUSTOM:-\$ZSH/custom}/plugins/zsh-autosuggestions"

# Plugin configurations
# SSH Agent configuration
zstyle :omz:plugins:ssh-agent agent-forwarding on
zstyle :omz:plugins:ssh-agent identities id_rsa

# === HOMEBREW CONFIGURATION ===
# Homebrew wrapper if available (platform-aware)
if command -v brew >/dev/null 2>&1; then
  local brew_prefix="$(brew --prefix)"
  if [ -f "$brew_prefix/etc/brew-wrap" ]; then
    source "$brew_prefix/etc/brew-wrap"
  fi
  
  # Homebrew environment variables
  export HOMEBREW_BREWFILE="${DOTFILES_DIR:-$HOME/dotfiles}/Brewfile"
  export HOMEBREW_BREWFILE_BACKUP="${DOTFILES_DIR:-$HOME/dotfiles}/Brewfile.bak"
  export HOMEBREW_BREWFILE_APPSTORE=1
  export HOMEBREW_NO_ENV_HINTS=1
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_AUTOREMOVE=1
  export HOMEBREW_NO_INSTALL_UPGRADE=1

  # MANPATH settings (only needed on macOS for GNU tools)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    prepend_manpath "$brew_prefix/opt/findutils/share/man"
    prepend_manpath "$brew_prefix/opt/gawk/share/man"
    prepend_manpath "$brew_prefix/opt/less/share/man"
    prepend_manpath "$brew_prefix/opt/erlang/lib/erlang/man"
  fi
fi

# Load Oh-My-Zsh
source "$ZSH/oh-my-zsh.sh"

# === BASH COMPATIBILITY ===
# Bash completion compatibility
complete () {
  emulate -L zsh
  local args void cmd print remove
  args=("$@")
  zparseopts -D -a void o: A: G: W: C: F: P: S: X: a b c d e f g j k u v p=print r=remove
  if [[ -n $print ]]; then
    printf 'complete %2$s %1$s\n' "${(@kv)_comps[(R)_bash*]#* }"
  elif [[ -n $remove ]]; then
    for cmd; do
      unset "_comps[$cmd]"
    done
  else
    compdef _bash_complete\ ${(j. .)${(q)args[1,-1-$#]}} "$@"
  fi
}

# === HISTORY SETTINGS ===
# History file configuration 
export HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=1000000
SAVEHIST=1000000

# History command configuration
setopt EXTENDED_HISTORY       # Save timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt HIST_IGNORE_DUPS       # Don't record if same as previous command
setopt HIST_IGNORE_ALL_DUPS   # Delete old duplicate entries
setopt HIST_FIND_NO_DUPS      # Don't display duplicates during searches
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
setopt HIST_REDUCE_BLANKS     # Remove unnecessary blanks
setopt HIST_SAVE_NO_DUPS      # Don't save duplicates
setopt HIST_NO_STORE          # Don't store history command itself
setopt HIST_FCNTL_LOCK        # Better concurrent access
setopt INC_APPEND_HISTORY     # Add commands as they are typed, not at shell exit
setopt SHARE_HISTORY          # Share history between different instances

# Ignore common commands
HISTORY_IGNORE="(ls|pwd|exit|clear|history)"

# History search functions
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# === KEYBINDINGS ===
bindkey -e  # Emacs style bindings (default)

# Word movement with Option+Arrow keys
bindkey "\e\e[D" backward-word          # Option+Left
bindkey "\e\e[C" forward-word           # Option+Right
bindkey "^[b" backward-word             # Option+b - alternative for terminals
bindkey "^[f" forward-word              # Option+f - alternative for terminals

# History search with Up/Down - search based on what you've typed
bindkey "^[[A" up-line-or-beginning-search        # Up
bindkey "^[[B" down-line-or-beginning-search      # Down

# Line navigation
bindkey "^[[H" beginning-of-line        # Home (Command+Left on Mac keyboard)
bindkey "^[[F" end-of-line              # End (Command+Right on Mac keyboard)
bindkey "^A" beginning-of-line          # Ctrl+A - alternative for terminals
bindkey "^E" end-of-line                # Ctrl+E - alternative for terminals
bindkey "^[[3~" delete-char             # Delete

# History search with Ctrl+R/S
bindkey '^R' history-incremental-search-backward  # Ctrl+R
bindkey '^S' history-incremental-search-forward   # Ctrl+S

# History navigation with Ctrl+P/N
bindkey '^P' history-beginning-search-backward    # Ctrl+P
bindkey '^N' history-beginning-search-forward     # Ctrl+N

# Edit command in editor
bindkey '^X^E' edit-command-line        # Ctrl+X then Ctrl+E - edit in $EDITOR

# Common shell actions
bindkey '^U' kill-whole-line            # Ctrl+U - delete entire line
bindkey '^K' kill-line                  # Ctrl+K - delete from cursor to end
bindkey '^W' backward-kill-word         # Ctrl+W - delete previous word
bindkey '^Y' yank                       # Ctrl+Y - paste what was cut

# === LANGUAGE AND LOCALE ===
export LANG=en_US.UTF-8
export LC_CTYPE=UTF-8
export LC_NUMERIC="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_PAPER="en_US.UTF-8"
export LC_NAME="en_US.UTF-8"
export LC_ADDRESS="en_US.UTF-8"
export LC_TELEPHONE="en_US.UTF-8"
export LC_MEASUREMENT="en_US.UTF-8"
export LC_IDENTIFICATION="en_US.UTF-8"
export LC_ALL=

# === ASDF VERSION MANAGER ===
# Initialize ASDF (platform-aware)
if command -v brew >/dev/null 2>&1; then
  local brew_prefix="$(brew --prefix)"
  if [ -f "$brew_prefix/opt/asdf/libexec/asdf.sh" ]; then
    . "$brew_prefix/opt/asdf/libexec/asdf.sh"

    # Add asdf completions - needed for zsh
    if [ -d "${ASDF_DIR}/completions" ]; then
      fpath=(${ASDF_DIR}/completions $fpath)
      # Ensure completions are loaded without compiling
      autoload -Uz compinit
      compinit -D
    fi
  fi
elif command -v asdf >/dev/null 2>&1; then
  # asdf installed via other means (e.g., direct installation on Linux)
  # Modern asdf 0.17+ should work via shims in PATH
  true
fi

# === DEVELOPMENT SETTINGS ===
# Java
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8 -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false"
export ANT_OPTS="-Xmx4096m"
export MAVEN_OPTS="-Xmx4096m"
export GRADLE_OPTS="-Xmx4096m -Xms2024m"

# AWS
export AWS_PAGER=""
export AWS_SDK_LOAD_CONFIG=1
[[ -f "$HOME/.aws/github_token" ]] && source "$HOME/.aws/github_token"

# Kubernetes
export KUBECONFIG="$XDG_CONFIG_HOME/kube/config"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
# KICS queries path (platform-aware)
if command -v brew >/dev/null 2>&1; then
  local brew_prefix="$(brew --prefix)"
  export KICS_QUERIES_PATH="$brew_prefix/opt/kics/share/kics/assets/queries"
fi
alias k=kubectl

# Terraform
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
export TFENV_ARCH=arm64

# Other dev tools
export JMETER_HOME=/usr/local/opt/jmeter
export VAGRANT_DEFAULT_PROVIDER=virtualbox

# === ALIASES ===
alias mtr="mtr --curses"
alias vim=nvim
alias vi=nvim
alias t="top -ocpu -R -F -s 2 -n30"
alias gist='gist -p'
alias h='fc -li 1'
alias hs='history | grep'

# Copy/move with progress bar
alias rsynccopy="rsync --partial --progress --append --rsh=ssh -r -h"
alias rsyncmove="rsync --partial --progress --append --rsh=ssh -r -h --remove-sent-files"

# === FUNCTIONS ===
# Compact JDK version switcher
setjdk() {
  [ -z "$1" ] && { /usr/libexec/java_home -V 2>&1 | grep -E "\s+\d" | cut -d, -f1; return; }

  local jhome=$(/usr/libexec/java_home -v "$1" 2>/dev/null) || {
    echo "Java $1 not found";
    /usr/libexec/java_home -V 2>&1 | grep -E "\s+\d" | cut -d, -f1;
    return 1;
  }

  [ -n "$JAVA_HOME" ] && PATH=${PATH//$JAVA_HOME\/bin:/}
  export JAVA_HOME=$jhome
  export PATH=$JAVA_HOME/bin:$PATH

  # Only show version info if verbose flag is passed
  [ "$2" = "-v" ] && java -version
}

# Set default Java version to 21
setjdk 21

# List GCP projects
function list() {
  case $1 in
    projects)
      gcloud projects list --format 'table(name:sort=1,projectId,parent.id:label=Parent)'
      ;;
    *)
      ;;
  esac
}

# Remove git branches that have been deleted upstream
function rm_local_branches() {
  if [ $(git rev-parse --is-inside-work-tree 2> /dev/null) = "true" ]; then
    echo "deleting local branches that do not have a remote"
    git fetch --all -p; git branch -vv | grep ": gone]" | awk '{ print $1 }' | xargs -r -n 1 git branch -D
  else
    echo "not a git repo"
  fi
}

# Install missing oh-my-zsh plugins
function install_zsh_plugins() {
  echo "Installing missing oh-my-zsh plugins..."
  
  local custom_dir="${ZSH_CUSTOM:-$ZSH/custom}"
  
  # zsh-completions
  if [[ ! -d "$custom_dir/plugins/zsh-completions" ]]; then
    echo "Installing zsh-completions..."
    git clone https://github.com/zsh-users/zsh-completions "$custom_dir/plugins/zsh-completions"
  fi
  
  # zsh-syntax-highlighting
  if [[ ! -d "$custom_dir/plugins/zsh-syntax-highlighting" ]]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_dir/plugins/zsh-syntax-highlighting"
  fi
  
  # zsh-autosuggestions
  if [[ ! -d "$custom_dir/plugins/zsh-autosuggestions" ]]; then
    echo "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/plugins/zsh-autosuggestions"
  fi
  
  echo "Plugin installation complete! Restart your shell or run 'source ~/.zshrc' to activate."
}

# === SSH AGENT CONFIGURATION ===

# === EXTERNAL TOOLS INTEGRATION ===
# iTerm2 integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# direnv - lazy load
direnv() {
  unfunction direnv
  eval "$(command direnv hook zsh)"
  direnv "$@"
}

# SDKMAN
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Google Cloud SDK - load once (platform-aware)
if command -v brew >/dev/null 2>&1; then
  local brew_prefix="$(brew --prefix)"
  if [ -f "$brew_prefix/share/google-cloud-sdk/path.zsh.inc" ]; then
    source "$brew_prefix/share/google-cloud-sdk/path.zsh.inc"
  fi
  if [ -f "$brew_prefix/share/google-cloud-sdk/completion.zsh.inc" ]; then
    source "$brew_prefix/share/google-cloud-sdk/completion.zsh.inc"
  fi
fi

# === PERSONAL SETTINGS ===
export DEBFULLNAME="Sebastian Otaegui"
export DEBEMAIL="feniix@gmail.com"
export EDITOR=nvim
export GPG_TTY=$(tty)

# === POWERLEVEL10K ===
# Source Powerlevel10k theme (platform-aware)
# macOS: /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
# Linux: /home/linuxbrew/.linuxbrew/share/powerlevel10k/powerlevel10k.zsh-theme
if command -v brew >/dev/null 2>&1; then
  local brew_prefix="$(brew --prefix)"
  local p10k_theme="$brew_prefix/share/powerlevel10k/powerlevel10k.zsh-theme"
  if [[ -f "$p10k_theme" ]]; then
    source "$p10k_theme"
  else
    # Debug: Show where we're looking for the theme
    echo "Powerlevel10k theme not found at: $p10k_theme" >&2
  fi
elif [[ -f "/usr/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  # Fallback: System-wide installation (e.g., via package manager)
  source "/usr/share/powerlevel10k/powerlevel10k.zsh-theme"
elif [[ -f "$HOME/.powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  # Fallback: User installation
  source "$HOME/.powerlevel10k/powerlevel10k.zsh-theme"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
echo "Loading $0"
