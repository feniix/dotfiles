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
  
  # Start with a minimal PATH that prioritizes Homebrew
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin"
  
  # Add homebrew core utils next (highest priority after base homebrew)
  export PATH="$PATH:/opt/homebrew/opt/curl/bin"
  export PATH="$PATH:/opt/homebrew/opt/make/libexec/gnubin"
  export PATH="$PATH:/opt/homebrew/opt/gnu-getopt/bin"
  export PATH="$PATH:/opt/homebrew/opt/python@3.11/bin"
  export PATH="$PATH:/opt/homebrew/opt/gnupg@2.2/bin"
  export PATH="$PATH:/opt/homebrew/opt/gnu-tar/libexec/gnubin"
  export PATH="$PATH:/opt/homebrew/opt/findutils/bin"
  export PATH="$PATH:/opt/homebrew/opt/gawk/bin"
  export PATH="$PATH:/opt/homebrew/opt/less/bin"
  export PATH="$PATH:/opt/homebrew/opt/openssl@1.1/bin"
  export PATH="$PATH:/opt/homebrew/opt/libpq/bin"
  export PATH="$PATH:/opt/homebrew/opt/ssh-copy-id/bin"
  
  # Tool-specific paths
  export PATH="$PATH:${KREW_ROOT:-$HOME/.krew}/bin"
  export PATH="$PATH:$HOME/.linkerd2/bin"
  export PATH="$PATH:$HOME/.docker/bin"
  export PATH="$PATH:$HOME/.config/tempus-app-manager/bin"
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
  export PATH="$PATH:/opt/homebrew/Cellar/bonnie++/2.00a/bin"
  export PATH="$PATH:/opt/homebrew/Cellar/bonnie++/2.00a/sbin"
  
  # Add user directories next
  export PATH="$PATH:$HOME/bin:$HOME/sbin:$HOME/go/bin"
  
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
  FPATH="/opt/homebrew/share/zsh/site-functions:/opt/homebrew/share/zsh-completions:$FPATH"
  # Skip global compinit in oh-my-zsh, we'll call it once efficiently
  skip_global_compinit=1
  
  # Load completions
  autoload -Uz compinit
  # Only rebuild completion cache once a week
  if [ $(date +'%j') != $(/usr/bin/stat -f '%Sm' -t '%j' ${ZDOTDIR:-$HOME}/.zcompdump 2>/dev/null) ]; then
    compinit
  else
    compinit -C
  fi
  
  # Completion caching
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path ~/.zsh/cache
  
  # Better completion options
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

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
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# === PLUGIN CONFIGURATION ===
# Core plugins - always loaded
plugins=(
  # Essentials
  history-substring-search
  colored-man-pages
  command-not-found
  zsh-completions
  
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

# Plugin configurations
# SSH Agent configuration
zstyle :omz:plugins:ssh-agent agent-forwarding on
zstyle :omz:plugins:ssh-agent identities id_rsa

# === HOMEBREW CONFIGURATION ===
# Homebrew wrapper if available
if [ -f /opt/homebrew/etc/brew-wrap ]; then
  source /opt/homebrew/etc/brew-wrap
fi

# Homebrew environment variables
export HOMEBREW_BREWFILE=~/dotfiles/Brewfile
export HOMEBREW_BREWFILE_BACKUP=~/dotfiles/Brewfile.bak
export HOMEBREW_BREWFILE_APPSTORE=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_AUTOREMOVE=1
export HOMEBREW_NO_INSTALL_UPGRADE=1

# MANPATH settings
prepend_manpath "/opt/homebrew/opt/findutils/share/man"
prepend_manpath "/opt/homebrew/opt/gawk/share/man"
prepend_manpath "/opt/homebrew/opt/less/share/man"
prepend_manpath "/opt/homebrew/opt/erlang/lib/erlang/man"

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
HISTFILE=~/.zsh_history
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
setopt HIST_VERIFY            # Show command with history expansion before running it
setopt HIST_BEEP              # Beep when accessing nonexistent history
setopt INC_APPEND_HISTORY     # Add commands as they are typed, not at shell exit
setopt SHARE_HISTORY          # Share history between different instances

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
# Initialize ASDF
if [ -f "/opt/homebrew/opt/asdf/libexec/asdf.sh" ]; then
  . /opt/homebrew/opt/asdf/libexec/asdf.sh
  
  # Add asdf completions - needed for zsh
  if [ -d "${ASDF_DIR}/completions" ]; then
    fpath=(${ASDF_DIR}/completions $fpath)
    # Ensure completions are loaded
    autoload -Uz compinit
    compinit
  fi
fi

# === DEVELOPMENT SETTINGS ===
# Java
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8 -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false"
export ANT_OPTS="-Xmx2024m -XX:MaxPermSize=256m"
export MAVEN_OPTS="-Xmx2024m -XX:MaxPermSize=256m"
export GRADLE_OPTS="-Xmx2024m -Xms2024m"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/opt/homebrew/opt/openssl@1.1"

# OpenSSL
export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"

# AWS
export AWS_PAGER=""
export AWS_SDK_LOAD_CONFIG=1
[[ -f "$HOME/.aws/github_token" ]] && source "$HOME/.aws/github_token"

# Kubernetes
export KUBECONFIG=$HOME/.kube/config
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export KICS_QUERIES_PATH="/opt/homebrew/opt/kics/share/kics/assets/queries"
alias k=kubectl

# Terraform
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
export TFENV_ARCH=arm64

# Other dev tools
export PACKER_CACHE_DIR=${HOME}/.packer
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

# === SSH AGENT CONFIGURATION ===
# Remove FreeDRP known hosts to prevent issues
rm -rf ~/.freerdp/known_hosts

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

# Google Cloud SDK - load once
if [ -f /opt/homebrew/share/google-cloud-sdk/path.zsh.inc ]; then
  source /opt/homebrew/share/google-cloud-sdk/path.zsh.inc
fi
if [ -f /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc ]; then
  source /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc
fi

# === PERSONAL SETTINGS ===
export DEBFULLNAME="Sebastian Otaegui"
export DEBEMAIL="feniix@gmail.com"
export EDITOR=nvim
export GPG_TTY=$(tty)

# === POWERLEVEL10K ===
# Source Powerlevel10k theme
if [[ -f /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
