# Path to your oh-my-zsh configuration.
# Uncomment to profile zsh startup
#zmodload zsh/zprof

# === OH-MY-ZSH CONFIGURATION ===
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$HOME/dotfiles/zsh_custom

# Theme configuration
ZSH_THEME="bullet-train"
BULLETTRAIN_PROMPT_ORDER=(
  status
  custom
  context
  dir
  kctx
  aws
  git
  cmd_exec_time
)

# Bullet train settings
BULLETTRAIN_KCTX_KCONFIG="$HOME/.kube/config"
BULLETTRAIN_STATUS_EXIT_SHOW=true
BULLETTRAIN_RUBY_FG=black
BULLETTRAIN_DIR_FG=black
BULLETTRAIN_GIT_FG=white
BULLETTRAIN_GIT_BG=black
BULLETTRAIN_DIR_EXTENDED=2
BULLETTRAIN_KCTX_FG=black

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

# Conditionally add plugins based on installed tools
# Only load these plugins if the related command exists
if command -v gem &>/dev/null; then plugins+=(gem); fi
if command -v npm &>/dev/null; then plugins+=(npm); fi
if command -v nmap &>/dev/null; then plugins+=(nmap); fi
if command -v rsync &>/dev/null; then plugins+=(rsync); fi
if command -v ssh-agent &>/dev/null; then plugins+=(ssh-agent); fi
if command -v vagrant &>/dev/null; then plugins+=(vagrant); fi

# Plugin configurations
# SSH Agent configuration
zstyle :omz:plugins:ssh-agent agent-forwarding on
zstyle :omz:plugins:ssh-agent identities id_rsa

# === PATH CONFIGURATION ===
# Homebrew
if [ -f /opt/homebrew/etc/brew-wrap ]; then
  source /opt/homebrew/etc/brew-wrap
fi

export HOMEBREW_BREWFILE=~/dotfiles/Brewfile
export HOMEBREW_BREWFILE_BACKUP=~/dotfiles/Brewfile.bak
export HOMEBREW_BREWFILE_APPSTORE=1

# Helper functions for PATH management
# Add to PATH only if directory exists
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

# Homebrew base (highest priority)
prepend_path "/opt/homebrew/bin"
prepend_path "/opt/homebrew/sbin"

# GNU and core utils
prepend_path "/opt/homebrew/opt/curl/bin"
prepend_path "/opt/homebrew/opt/make/libexec/gnubin"
prepend_path "/opt/homebrew/opt/gnu-getopt/bin"
prepend_path "/opt/homebrew/opt/python@3.11/bin"
prepend_path "/opt/homebrew/opt/gnupg@2.2/bin"
prepend_path "/opt/homebrew/opt/gnu-tar/libexec/gnubin"
prepend_path "/opt/homebrew/opt/findutils/bin"
prepend_path "/opt/homebrew/opt/gawk/bin"
prepend_path "/opt/homebrew/opt/less/bin"
prepend_path "/opt/homebrew/opt/openssl@1.1/bin"
prepend_path "/opt/homebrew/opt/libpq/bin"
prepend_path "/opt/homebrew/opt/ssh-copy-id/bin"

# Tool paths
prepend_path "${KREW_ROOT:-$HOME/.krew}/bin"
prepend_path "$HOME/.linkerd2/bin"
prepend_path "$HOME/.docker/bin"
prepend_path "$HOME/.fiberplane"
prepend_path "$HOME/.config/tempus-app-manager/bin"

# Personal paths
prepend_path "$HOME/sbin"
prepend_path "$HOME/bin"
prepend_path "$HOME/go/bin"
prepend_path "/opt/homebrew/Cellar/bonnie++/2.00a/bin"
prepend_path "/opt/homebrew/Cellar/bonnie++/2.00a/sbin"

# JetBrains Toolbox
prepend_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# MANPATH settings
prepend_manpath "/opt/homebrew/opt/findutils/share/man"
prepend_manpath "/opt/homebrew/opt/gawk/share/man"
prepend_manpath "/opt/homebrew/opt/less/share/man"
prepend_manpath "/opt/homebrew/opt/erlang/lib/erlang/man"

# Load Oh-My-Zsh
source "$ZSH/oh-my-zsh.sh"

# === COMPLETION SETTINGS ===
if type brew &>/dev/null; then
  FPATH=/opt/homebrew/completions/zsh:/opt/homebrew/share/zsh-completions:$FPATH
  autoload -Uz compinit && compinit
fi

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

# Completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

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

# History search keybindings
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down
bindkey '^R' history-incremental-search-backward # Ctrl+R
bindkey '^S' history-incremental-search-forward  # Ctrl+S
bindkey '^P' history-beginning-search-backward  # Ctrl+P
bindkey '^N' history-beginning-search-forward   # Ctrl+N

# History display improvements
alias h='fc -li 1'
alias hs='history | grep'

# === PERSONAL SETTINGS ===
export DEBFULLNAME="Sebastian Otaegui"
export DEBEMAIL="feniix@gmail.com"
export EDITOR=nvim

# === KEYBINDINGS ===
bindkey -e
bindkey "\e\e[D" backward-word # alt + <-
bindkey "\e\e[C" forward-word # alt + ->

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

# Copy/move with progress bar
alias rsynccopy="rsync --partial --progress --append --rsh=ssh -r -h"
alias rsyncmove="rsync --partial --progress --append --rsh=ssh -r -h --remove-sent-files"

# === FUNCTIONS ===
# Set JDK version
function setjdk() {
  if [ $# -ne 0 ]; then
    removeFromPath '/System/Library/Frameworks/JavaVM.framework/Home/bin'
    if [ -n "${JAVA_HOME+x}" ]; then
      removeFromPath $JAVA_HOME/bin
    fi
    declare -x JAVA_HOME
    JAVA_HOME=$(/usr/libexec/java_home -v $@)
    export PATH=$JAVA_HOME/bin:$PATH
  fi
}

# Helper for setjdk
function removeFromPath() {
  export PATH=$(echo "$PATH" | sed -E -e "s;:$1;;" -e "s;$1:?;;")
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

# direnv
eval "$(direnv hook zsh)"

# SDKMAN
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Google Cloud SDK
if [ -f /opt/homebrew/share/google-cloud-sdk/path.zsh.inc ]; then
  source /opt/homebrew/share/google-cloud-sdk/path.zsh.inc
fi
if [ -f /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc ]; then
  source /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc
fi

# Fiberplane CLI completions
source /Users/feniix/.fiberplane/zsh_completions

# Uncomment to see zsh profiling info
#zprof
