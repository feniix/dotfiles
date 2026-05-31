{ config, pkgs, lib, dotfilesDir, ... }:

let
  p10kThemeFile = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    # Disabled because we run our own compinit with the weekly-rebuild trick below.
    enableCompletion = false;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 100000;
      save = 100000;
      path = "${config.xdg.stateHome}/zsh/history";
      extended = true;
      share = true;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      findNoDups = true;
      ignoreSpace = true;
    };

    shellAliases = {
      ahr = "_async_history_reload";
      gist = "gist -p";
      h = "fc -li 1";
      hms = "home-manager switch --flake ~/dotfiles/home-manager";
      hr = "reload_shared_history";
      hs = "history | grep";
      k = "kubectl";
      la = "eza -la --group-directories-first --git";
      ll = "eza -l --group-directories-first --git";
      ls = "eza --group-directories-first";
      lt = "eza --tree --level=2 --group-directories-first";
      mtr = "mtr --curses";
      rsynccopy = "rsync --partial --progress --append --rsh=ssh -r -h";
      rsyncmove = "rsync --partial --progress --append --rsh=ssh -r -h --remove-sent-files";
      t = "top -ocpu -R -F -s 2 -n30";
      vi = "nvim";
      vim = "nvim";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "history-substring-search"
        "colored-man-pages"
        "last-working-dir"
        "sudo"
        "gnu-utils"
        "git"
        "git-extras"
        "python"
        "pip"
        "rust"
        "docker"
        "docker-compose"
        "kubectl"
        "aws"
        "ant"
        "gradle"
        "mvn"
      ];
    };

    # Goes into ~/.zshenv (sourced before every shell).
    envExtra = ''
      # XDG runtime dir (needs runtime $(id -u))
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/tmp/runtime-$(id -u)}"
      if [ ! -d "$XDG_RUNTIME_DIR" ]; then
        mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null && chmod 0700 "$XDG_RUNTIME_DIR"
      fi

      # Ensure XDG tool state dirs exist
      [ -d "''${XDG_STATE_HOME:-$HOME/.local/state}/zsh" ]  || mkdir -p "''${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
      [ -d "''${XDG_STATE_HOME:-$HOME/.local/state}/less" ] || mkdir -p "''${XDG_STATE_HOME:-$HOME/.local/state}/less"
      [ -d "''${XDG_STATE_HOME:-$HOME/.local/state}/node" ] || mkdir -p "''${XDG_STATE_HOME:-$HOME/.local/state}/node"
      [ -d "''${XDG_DATA_HOME:-$HOME/.local/share}/curl" ] || mkdir -p "''${XDG_DATA_HOME:-$HOME/.local/share}/curl"

      # Homebrew shellenv (early, so PATH is sane before .zshrc runs)
      if [ -z "$HOMEBREW_PREFIX" ] && [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      # Nix daemon (in case profile didn't add it)
      if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '';

    initContent = lib.mkMerge [
      # Runs BEFORE oh-my-zsh sources (compinit, paths, OMZ knobs).
      (lib.mkBefore ''
        # P10k instant prompt — must stay at the top of .zshrc
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        # === PATH helpers ===
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

        reset_path() {
          local usr_local_bin="/usr/local/bin"
          local usr_bin="/usr/bin"
          local usr_sbin="/usr/sbin"
          local bin="/bin"
          local sbin="/sbin"

          eval $(brew shellenv)

          export PATH="$PATH:/opt/homebrew/opt/curl/bin"
          export PATH="$PATH:/opt/homebrew/opt/make/libexec/gnubin"
          export PATH="$PATH:/opt/homebrew/opt/gnu-getopt/bin"
          export PATH="$PATH:/opt/homebrew/opt/gnu-tar/libexec/gnubin"
          export PATH="$PATH:/opt/homebrew/opt/findutils/bin"
          export PATH="$PATH:/opt/homebrew/opt/gawk/bin"
          export PATH="$PATH:/opt/homebrew/opt/less/bin"
          export PATH="$PATH:/opt/homebrew/opt/libpq/bin"
          export PATH="$PATH:/opt/homebrew/opt/ssh-copy-id/bin"

          export PATH="$PATH:''${KREW_ROOT:-$HOME/.krew}/bin"
          export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

          export PATH="$PATH:$HOME/bin:$HOME/.local/share/go/bin"
          export PATH="$PATH:$usr_local_bin:$usr_bin:$usr_sbin:$bin:$sbin"
        }

        reset_path
        prepend_path "$HOME/.local/bin"

        debug_path() {
          echo "=== PATH ==="
          echo $PATH | tr ':' '\n' | nl
          echo ""
          echo "=== MANPATH ==="
          echo $MANPATH | tr ':' '\n' | nl
          echo ""
          echo "=== Non-existent directories in PATH ==="
          for p in $(echo $PATH | tr ':' '\n'); do
            if [[ ! -d "$p" ]]; then
              echo "MISSING: $p"
            fi
          done
        }

        # === Completion (custom compinit with weekly rebuild) ===
        if type brew &>/dev/null; then
          FPATH="/opt/homebrew/share/zsh/site-functions:/opt/homebrew/share/zsh-completions:$FPATH"
          skip_global_compinit=1

          autoload -Uz compinit
          # Quoted both sides — when .zcompdump doesn't exist yet (first run),
          # the stat $() expands to empty and the unquoted form is a parse error.
          if [[ "$(date +'%j')" != "$(/usr/bin/stat -f '%Sm' -t '%j' ''${ZDOTDIR:-$HOME}/.zcompdump 2>/dev/null)" ]]; then
            compinit -D
          else
            compinit -D -C
          fi

          zstyle ':completion:*' use-cache on
          zstyle ':completion:*' cache-path ~/.zsh/cache
          zstyle ':completion:*' menu select
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
          zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        fi

        # === OMZ perf knobs (must be set before OMZ loads) ===
        DISABLE_AUTO_UPDATE="true"
        DISABLE_UPDATE_PROMPT="true"
        DISABLE_MAGIC_FUNCTIONS="true"
        COMPLETION_WAITING_DOTS="false"
        DISABLE_UNTRACKED_FILES_DIRTY="true"
        # ZSH_DISABLE_COMPFIX is set in home.sessionVariables (loaded via .zshenv)

        # === MANPATH for Homebrew GNU tools ===
        prepend_manpath "/opt/homebrew/opt/findutils/share/man"
        prepend_manpath "/opt/homebrew/opt/gawk/share/man"
        prepend_manpath "/opt/homebrew/opt/less/share/man"

        # === Async git prompt (OMZ Apr 2024 feature) ===
        zstyle ':omz:alpha:lib:git' async-prompt yes
      '')

      # Default-priority block: runs AFTER oh-my-zsh sources.
      ''
        # === History substring search (after OMZ loads the plugin) ===
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        bindkey '^[OA' history-substring-search-up
        bindkey '^[OB' history-substring-search-down
        bindkey -M emacs '^[[A' history-substring-search-up
        bindkey -M emacs '^[[B' history-substring-search-down
        bindkey -M emacs '^[OA' history-substring-search-up
        bindkey -M emacs '^[OB' history-substring-search-down

        # === Bash completion compatibility shim ===
        complete () {
          emulate -L zsh
          local args void cmd print remove
          args=("$@")
          zparseopts -D -a void o: A: G: W: C: F: P: S: X: a b c d e f g j k u v p=print r=remove
          if [[ -n $print ]]; then
            printf 'complete %2$s %1$s\n' "''${(@kv)_comps[(R)_bash*]#* }"
          elif [[ -n $remove ]]; then
            for cmd; do
              unset "_comps[$cmd]"
            done
          else
            compdef _bash_complete\ ''${(j. .)''${(q)args[1,-1-$#]}} "$@"
          fi
        }

        # === Extra history setopts not covered by programs.zsh.history ===
        setopt HIST_REDUCE_BLANKS
        setopt HIST_NO_STORE
        setopt HIST_FCNTL_LOCK

        # === Async history sharing ===
        autoload -U add-zsh-hook

        reload_shared_history() {
          timeout 2s fc -RI 2>/dev/null || {
            echo "History reload timed out - skipping"
            return 1
          }
        }

        typeset -g _async_history_counter=0

        _async_history_reload() {
          if (( ''${+functions[async_start_worker]} )); then
            async_start_worker history_worker -u
            async_job history_worker timeout 1s fc -RI
          else
            timeout 1s fc -RI 2>/dev/null || true
          fi
        }

        _periodic_async_history_reload() {
          (( _async_history_counter++ ))
          if (( _async_history_counter >= 5 )); then
            _async_history_reload
            _async_history_counter=0
          fi
        }

        add-zsh-hook precmd _periodic_async_history_reload

        autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search

        # === Keybindings ===
        bindkey -e
        bindkey "\e\e[D" backward-word
        bindkey "\e\e[C" forward-word
        bindkey "^[b" backward-word
        bindkey "^[f" forward-word
        bindkey "^[[H" beginning-of-line
        bindkey "^[[F" end-of-line
        bindkey "^A" beginning-of-line
        bindkey "^E" end-of-line
        bindkey "^[[3~" delete-char
        bindkey '^R' history-incremental-search-backward
        bindkey '^S' history-incremental-search-forward
        bindkey '^P' history-beginning-search-backward
        bindkey '^N' history-beginning-search-forward
        bindkey '^X^E' edit-command-line
        bindkey '^U' kill-whole-line
        bindkey '^K' kill-line
        bindkey '^W' backward-kill-word
        bindkey '^Y' yank

        # === AWS local secrets ===
        [[ -f "$HOME/.aws/github_token" ]] && source "$HOME/.aws/github_token"

        # === setjdk ===
        setjdk() {
          [ -z "$1" ] && { /usr/libexec/java_home -V 2>&1 | grep -E "\s+\d" | cut -d, -f1; return; }

          local jhome=$(/usr/libexec/java_home -v "$1" 2>/dev/null) || {
            echo "Java $1 not found"
            /usr/libexec/java_home -V 2>&1 | grep -E "\s+\d" | cut -d, -f1
            return 1
          }

          [ -n "$JAVA_HOME" ] && PATH=''${PATH//$JAVA_HOME\/bin:/}
          export JAVA_HOME=$jhome
          export PATH=$JAVA_HOME/bin:$PATH

          [ "$2" = "-v" ] && java -version
        }
        setjdk 21

        # === GCP project list helper ===
        function list() {
          case $1 in
            projects)
              gcloud projects list --format 'table(name:sort=1,projectId,parent.id:label=Parent)'
              ;;
            *)
              ;;
          esac
        }

        # === Prune local git branches whose remote is gone ===
        function rm_local_branches() {
          if [ $(git rev-parse --is-inside-work-tree 2> /dev/null) = "true" ]; then
            echo "deleting local branches that do not have a remote"
            git fetch --all -p; git branch -vv | grep ": gone]" | awk '{ print $1 }' | xargs -r -n 1 git branch -D
          else
            echo "not a git repo"
          fi
        }

        # === Bun ===
        if [[ -d "$HOME/.cache/.bun/bin" ]]; then
          export PATH="$HOME/.cache/.bun/bin:$PATH"
        fi

        # === GPG ===
        export GPG_TTY=$(tty)

        # === Powerlevel10k theme (from Nix, pinned by the flake) ===
        source ${p10kThemeFile}

        # === aws_completer ===
        if command -v aws_completer &>/dev/null; then
          complete -C aws_completer aws
        fi

        # === Source dotfiles companion files ===
        [[ -f "${dotfilesDir}/claude.source" ]] && source "${dotfilesDir}/claude.source"
        [[ -f "${dotfilesDir}/completion" ]] && source "${dotfilesDir}/completion"

        # === P10k config (symlinked from dotfiles via xdg.configFile) ===
        [[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
        typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
      ''
    ];
  };
}
