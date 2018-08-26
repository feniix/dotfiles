# Path to your oh-my-zsh configuration.
#zmodload zsh/zprof

export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

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


setopt prompt_subst
zplug caiogondim/bullet-train.zsh, use:bullet-train.zsh-theme, defer:3

zplug plugins/ant, from:oh-my-zsh
zplug plugins/colored-man, from:oh-my-zsh
zplug plugins/command-not-found, from:oh-my-zsh
zplug plugins/common-aliases, from:oh-my-zsh
zplug plugins/docker, from:oh-my-zsh
zplug plugins/docker-compose, from:oh-my-zsh
zplug plugins/gem, from:oh-my-zsh
zplug plugins/git, from:oh-my-zsh
zplug plugins/git-extras, from:oh-my-zsh
zplug plugins/gnu-utils, from:oh-my-zsh
zplug plugins/gpg-agent, from:oh-my-zsh
zplug plugins/gradle, from:oh-my-zsh
zplug plugins/grails, from:oh-my-zsh
zplug plugins/history-substring-search, from:oh-my-zsh
zplug plugins/last-working-dir, from:oh-my-zsh
zplug plugins/mvn, from:oh-my-zsh
zplug plugins/nmap, from:oh-my-zsh
zplug plugins/npm, from:oh-my-zsh
zplug plugins/pip, from:oh-my-zsh
zplug plugins/rsync, from:oh-my-zsh
zplug plugins/rust, from:oh-my-zsh
zplug plugins/ssh-agent, from:oh-my-zsh
zplug plugins/sudo, from:oh-my-zsh
zplug plugins/svn, from:oh-my-zsh
zplug plugins/vagrant, from:oh-my-zsh
zplug plugins/zsh_reload, from:oh-my-zsh

zplug load

zstyle :compinstall filename "$HOME/.zshrc"
zstyle :omz:plugins:ssh-agent agent-forwarding on
zstyle :omz:plugins:ssh-agent identities id_rsa

autoload -Uz compinit
compinit

set -o monitor

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

#-------------------------------#

#export WORKON_HOME="$HOME/VEnvs"
#source /usr/local/bin/virtualenvwrapper.sh

# The next line updates PATH for the Google Cloud SDK.
#[[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc"

# The next line enables shell command completion for gcloud.
#[[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
#export SDKMAN_DIR="$HOME/.sdkman"
#[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# kubectl completion
#if which -s kops    > /dev/null ; then source <(kops completion zsh 2>/dev/null); fi
#if which -s kubectl > /dev/null ; then source <(kubectl completion zsh 2>/dev/null) ; fi

source $HOME/.asdf/asdf.sh
source $HOME/.asdf/completions/asdf.bash

eval "$(direnv hook zsh)"

#eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"

export PATH="$PATH:$HOME/istio-1.0.0/bin"

#zprof
