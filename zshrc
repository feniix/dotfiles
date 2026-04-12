# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh configuration.

# === PATH CONFIGURATION ===
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

# Reset PATH to ensure proper ordering
reset_path() {
  # Save important system paths that should be included but at lower priority
  local usr_local_bin="/usr/local/bin"
  local usr_bin="/usr/bin"
  local usr_sbin="/usr/sbin"
  local bin="/bin"
  local sbin="/sbin"

  eval $(brew shellenv)

  # Add homebrew core utils next (highest priority after base homebrew)
  export PATH="$PATH:/opt/homebrew/opt/curl/bin"
  export PATH="$PATH:/opt/homebrew/opt/make/libexec/gnubin"
  export PATH="$PATH:/opt/homebrew/opt/gnu-getopt/bin"
  export PATH="$PATH:/opt/homebrew/opt/gnu-tar/libexec/gnubin"
  export PATH="$PATH:/opt/homebrew/opt/findutils/bin"
  export PATH="$PATH:/opt/homebrew/opt/gawk/bin"
  export PATH="$PATH:/opt/homebrew/opt/less/bin"
  export PATH="$PATH:/opt/homebrew/opt/libpq/bin"
  export PATH="$PATH:/opt/homebrew/opt/ssh-copy-id/bin"

  # Tool-specific paths
  export PATH="$PATH:${KREW_ROOT:-$HOME/.krew}/bin"
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

  # Add user directories next
  export PATH="$PATH:$HOME/bin:$HOME/.local/share/go/bin"

  # Add system paths at lowest priority
  export PATH="$PATH:$usr_local_bin:$usr_bin:$usr_sbin:$bin:$sbin"
}

# Initialize with proper ordering
reset_path

# Ensure ~/.local/bin is first in PATH if it exists
prepend_path "$HOME/.local/bin"

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

  # Load completions without compiling
  autoload -Uz compinit
  # Only rebuild completion cache once a week, without compiling
  if [ $(date +'%j') != $(/usr/bin/stat -f '%Sm' -t '%j' ${ZDOTDIR:-$HOME}/.zcompdump 2>/dev/null) ]; then
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
COMPLETION_WAITING_DOTS="false"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# === PLUGIN CONFIGURATION ===
# Core plugins - always loaded
plugins=(
  # Essentials
  history-substring-search
  colored-man-pages
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

# === HOMEBREW CONFIGURATION ===
# Homebrew environment variables
export HOMEBREW_BREWFILE="${DOTFILES_DIR:-$HOME/dotfiles}/Brewfile"
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_AUTOREMOVE=1
export HOMEBREW_NO_INSTALL_UPGRADE=1

# MANPATH settings
prepend_manpath "/opt/homebrew/opt/findutils/share/man"
prepend_manpath "/opt/homebrew/opt/gawk/share/man"
prepend_manpath "/opt/homebrew/opt/less/share/man"

# Enable Oh-My-Zsh experimental async prompts (April 2024 feature)
zstyle ':omz:alpha:lib:git' async-prompt yes

# Load Oh-My-Zsh
source "$ZSH/oh-my-zsh.sh"

# === POST OH-MY-ZSH CONFIGURATION ===
# These need to come AFTER oh-my-zsh to avoid being overridden

# History substring search keybindings (must be after oh-my-zsh loads the plugin)
bindkey '^[[A' history-substring-search-up        # Up arrow
bindkey '^[[B' history-substring-search-down      # Down arrow
bindkey '^[OA' history-substring-search-up        # Up arrow (alternative)
bindkey '^[OB' history-substring-search-down      # Down arrow (alternative)

# Additional arrow key fix for iTerm2 reliability
# These bindings help when the above get reset by other processes
bindkey -M emacs '^[[A' history-substring-search-up
bindkey -M emacs '^[[B' history-substring-search-down
bindkey -M emacs '^[OA' history-substring-search-up
bindkey -M emacs '^[OB' history-substring-search-down

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
# Modern zsh history configuration optimized for oh-my-zsh
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=100000        # Large history size in memory
export SAVEHIST=100000        # Large history size on disk

# Core history behavior - optimized for real-time sharing
setopt EXTENDED_HISTORY       # Write the history file in the ':start:elapsed;command' format
setopt SHARE_HISTORY          # Share history between all sessions (includes INC_APPEND_HISTORY functionality)
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS       # Don't record an entry that was just recorded again
setopt HIST_FIND_NO_DUPS      # Do not display a line previously found
setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks before recording entry
setopt HIST_NO_STORE          # Remove the history (fc -l) command from the history list
setopt HIST_FCNTL_LOCK        # Use fcntl for better concurrent access to history file

# Enhanced history sharing - reload on demand, not every prompt
autoload -U add-zsh-hook

# Function to reload history when needed - made safer to prevent hanging
reload_shared_history() {
  # Use timeout to prevent hanging
  timeout 2s fc -RI 2>/dev/null || {
    echo "History reload timed out - skipping"
    return 1
  }
}

# Async history sharing using Oh-My-Zsh async infrastructure
# This leverages the experimental async functionality introduced in April 2024

# Counter for periodic async history reloads
typeset -g _async_history_counter=0

# Async history reload function - uses Oh-My-Zsh's async system
_async_history_reload() {
  # Use Oh-My-Zsh's async system if available
  if (( ${+functions[async_start_worker]} )); then
    # Oh-My-Zsh async system is available
    async_start_worker history_worker -u
    async_job history_worker timeout 1s fc -RI
  else
    # Fallback to simple timeout (should not cause prompt corruption with new async system)
    timeout 1s fc -RI 2>/dev/null || true
  fi
}

# Periodic async history check
_periodic_async_history_reload() {
  (( _async_history_counter++ ))
  if (( _async_history_counter >= 5 )); then
    _async_history_reload
    _async_history_counter=0
  fi
}

# Add to precmd hook - should work safely with Oh-My-Zsh async system
add-zsh-hook precmd _periodic_async_history_reload

# Manual reload alias for immediate sharing
alias hr='reload_shared_history'

# Manual async reload alias
alias ahr='_async_history_reload'

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

# History search with Up/Down - configured after oh-my-zsh loads
# (See POST OH-MY-ZSH CONFIGURATION section for actual bindings)

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


# === MISE VERSION MANAGER ===
# Initialize mise (reads ~/.config/mise/config.toml)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"

  # Add mise completions for zsh
  if [ -d "${HOME}/.local/share/mise/shims" ]; then
    fpath=(${HOME}/.local/share/mise $fpath)
  fi

  # Ensure ~/.local/bin stays first after mise modifies PATH
  prepend_path "$HOME/.local/bin"
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
alias k=kubectl

# Terraform
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
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

# === EXTERNAL TOOLS INTEGRATION ===
eval "$(command direnv hook zsh)"

# === PERSONAL SETTINGS ===
export EDITOR=nvim
export GPG_TTY=$(tty)

# === POWERLEVEL10K ===
# Source Powerlevel10k theme
if [[ -f /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
fi
if command -v aws_completer &>/dev/null; then
  complete -C aws_completer aws
fi

if [[ -f "${DOTFILES_DIR:-$HOME/dotfiles}/claude.source" ]]; then
  source "${DOTFILES_DIR:-$HOME/dotfiles}/claude.source"
fi
[[ -f "${DOTFILES_DIR:-$HOME/dotfiles}/completion" ]] && source "${DOTFILES_DIR:-$HOME/dotfiles}/completion"

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
