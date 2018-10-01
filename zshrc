# Path to your oh-my-zsh configuration.
#zmodload zsh/zprof

ZSH=$HOME/.oh-my-zsh

ZSH_CUSTOM=$HOME/dotfiles/zsh_custom

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="bullet-train"

BULLETTRAIN_PROMPT_ORDER=(
status
custom
context
dir
kctx
aws
git
hg
cmd_exec_time
)

BULLETTRAIN_KCTX_KCONFIG="$HOME/.kube/config"
BULLETTRAIN_STATUS_EXIT_SHOW=true
BULLETTRAIN_RUBY_FG=black
BULLETTRAIN_DIR_FG=black
BULLETTRAIN_GIT_FG=white
BULLETTRAIN_GIT_BG=black
BULLETTRAIN_DIR_EXTENDED=2
BULLETTRAIN_KCTX_FG=black

plugins=(
ant
colored-man
command-not-found
common-aliases
docker
docker-compose
gem
git
git-extras
gnu-utils
gpg-agent
gradle
grails
history-substring-search
last-working-dir
mix
mvn
nmap
npm
pip
rsync
rust
ssh-agent
sudo
svn
vagrant
zsh_reload
)

source "$ZSH/oh-my-zsh.sh"

export DEBFULLNAME="Sebastian Otaegui"
export DEBEMAIL="feniix@gmail.com"

# history settings
HISTFILE=~/.zsh_history
setopt INC_APPEND_HISTORY LIST_TYPES LONG_LIST_JOBS HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE AUTO_REMOVE_SLASH
export EDITOR=vim
export HISTSIZE=100000
export SAVEHIST=100000

#AMAZON EC2
export EC2_AMITOOL_HOME="/usr/local/Cellar/ec2-ami-tools/1.5.7/libexec"
export EC2_HOME="/usr/local/Cellar/ec2-api-tools/1.7.5.1/libexec"

export ANT_OPTS="-Xmx2024m -XX:MaxPermSize=256m"

export MAVEN_OPTS="-Xmx2024m -XX:MaxPermSize=256m"

export GRADLE_OPTS="-Xmx2024m -Xms2024m -XX:MaxPermSize=256m"

rm -rf ~/.freerdp/known_hosts

#config for the ssh-agent plugin
zstyle :omz:plugins:ssh-agent agent-forwarding on
zstyle :omz:plugins:ssh-agent identities id_rsa

# this is for homebrew
export PATH=/usr/local/bin:/usr/local/sbin:${PATH}

# for coreutils
#export PATH="/usr/local/opt/coreutils/libexec/gnubin:${PATH}"
#export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:${MANPATH}"

# for findutils
export PATH="/usr/local/opt/findutils/bin:${PATH}"
export MANPATH="/usr/local/opt/findutils/share/man:${MANPATH}"

# for gawk
export PATH="/usr/local/opt/gawk/bin:${PATH}"
export MANPATH="/usr/local/opt/gawk/share/man:${MANPATH}"

# for less
export PATH="/usr/local/opt/less/bin:${PATH}"
export MANPATH="/usr/local/opt/less/share/man:${MANPATH}"

# for gnu-sed
#export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:${PATH}"
#export MANPATH="/usr/local/opt/gnu-sed/libexec/gnuman:${MANPATH}"

export MANPATH="/usr/local/opt/erlang/lib/erlang/man:${MANPATH}"

PATH=${HOME}/sbin:$PATH

bindkey -e
bindkey "\e\e[D" backward-word # alt + <-
bindkey "\e\e[C" forward-word # alt + ->

export PACKER_CACHE_DIR=${HOME}/.packer

[[ -f "$HOME/.aws/github_token" ]] && source "$HOME/.aws/github_token"

#--------- begin alias ---------#

#alias dos2unix="todos -d"
#alias unix2dos="todos -u"
alias mtr="mtr --curses"

alias vi=vim

# copy / move with progress bar
alias rsynccopy="rsync --partial --progress --append --rsh=ssh -r -h "
alias rsyncmove="rsync --partial --progress --append --rsh=ssh -r -h --remove-sent-files"

alias t="top -ocpu -R -F -s 2 -n30"
alias kl=kubectl
alias kc=kubectx
alias ns=kubens

export ANDROID_HOME=/usr/local/opt/android-sdk

export GOPATH="$HOME/golang"
export PATH=${GOPATH}/bin:${PATH}
export GO15VENDOREXPERIMENT=1

export JMETER_HOME=/usr/local/opt/jmeter

# Java setup
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8 -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false"

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

function removeFromPath() {
  export PATH=$(echo "$PATH" | sed -E -e "s;:$1;;" -e "s;$1:?;;")
}
setjdk 1.8

[[ -f "/usr/local/share/zsh/site-functions/_aws" ]] && source "/usr/local/share/zsh/site-functions/_aws"

alias gist='gist -p'

export VAGRANT_DEFAULT_PROVIDER=virtualbox
unalias run-help
autoload run-help
export HELPDIR=/usr/local/share/zsh/help

function home_bin() {
  local home_bin=~/bin
  if ! test "${PATH#*$home_bin:}" != "$PATH"; then
    export PATH=~/bin:$PATH
  fi
}

function get_hg_password() {
  security find-generic-password -a otaegui -s healthgrades -w | pbcopy
}

function did_it_run() {
  local env
  local curr
  local last_run

  env=$1
  curr=$(date '+%s')
  last_run=0

  if [ -f "/tmp/.$env.lastrun" ]; then
    last_run=$(cat "/tmp/.$env.lastrun")
  fi

  local diff=$((curr - last_run))

  if [ $diff -gt 43200 ]; then
    echo -n "$curr" > "/tmp/.$env.lastrun"
    return 1
  fi
  return 0
}

function hg() {
  home_bin
  case $1 in
    dev|sandbox|infrastructure)
      get_hg_password
      export ENVIRONMENT=$1
      if [[ "${AWS_PROFILE}" != "hrm-$1"  ]]; then
        if ! did_it_run "hrm-$1"; then
          adfs-aws --user sotaegui --profile "hrm-$1" -r ADFS-HRMTest-Administrator
        fi
        export AWS_PROFILE="hrm-$1"
      fi
      kubectl config use-context exp-$1
      pbcopy <<<" "
      ;;
    uat)
      get_hg_password
      export ENVIRONMENT=$1
      if [[ "${AWS_PROFILE}" != "hrm-$1"  ]]; then
        if ! did_it_run "hrm-$1"; then
          adfs-aws --user sotaegui --profile "hrm-$1" -r ADFS-ExPPreProd-Administrator
        fi
        export AWS_PROFILE="hrm-$1"
      fi
      kubectl config use-context exp-$1
      pbcopy <<<" "
      ;;
    prod)
      get_hg_password
      export ENVIRONMENT=$1
      if [[ "${AWS_PROFILE}" != "hrm-$1"  ]]; then
        if ! did_it_run "hrm-$1"; then
          adfs-aws --user sotaegui --profile "hrm-$1" -r ADFS-ExPProd-Administrator
        fi
        export AWS_PROFILE="hrm-$1"
      fi
      kubectl config use-context exp-$1
      pbcopy <<<" "
      ;;
    unload)
      unset ENVIRONMENT
      unset AWS_PROFILE
      ;;
    *)
      #if (( ${+AWS_PROFILE} )); then
      #  echo "Current ENVIRONMENT=$ENVIRONMENT and AWS_PROFILE=$AWS_PROFILE"
      #fi
      #printf 'Use dev, sandbox, infrastructure, uat or prod. Use unload to logout\n'
      ;;
  esac
}

#-------------------------------#

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

source /usr/local/opt/asdf/asdf.sh
source /usr/local/etc/bash_completion.d/asdf.bash

source ~/sbin/kubectl-completion
source ~/sbin/kops-completion

eval "$(direnv hook zsh)"

export PATH="$PATH:$HOME/istio-1.0.0/bin"

#zprof
