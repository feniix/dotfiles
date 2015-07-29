# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="bira"

# Example aliases
alias zshconfig="vi ~/.zshrc"
alias ohmyzsh="vi ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
#COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
boot2docker
brew
brew-cask
bundler 
command-not-found 
common-aliases
colored-man
docker 
git 
git-extras
git-flow 
github 
gem 
gnu-utils 
gpg-agent
gradle
grails
history-substring-search 
last-working-dir
mvn 
npm
nvm
pip 
pj
rsync
rvm 
ssh-agent 
sudo
svn 
vagrant 
vundle 
zsh_reload
)

source "$ZSH/oh-my-zsh.sh"

export DEBFULLNAME="Sebastian Otaegui"
export DEBEMAIL="feniix@gmail.com"

# history settings
setopt INC_APPEND_HISTORY
setopt LIST_TYPES LONG_LIST_JOBS HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE
setopt AUTO_REMOVE_SLASH 
export EDITOR=vim
export HISTSIZE=100000
export SAVEHIST=100000

#AMAZON EC2
export EC2_AMITOOL_HOME="/usr/local/Cellar/ec2-ami-tools/1.5.7/libexec"
export EC2_HOME="/usr/local/Cellar/ec2-api-tools/1.7.4.0/libexec"

export ANT_OPTS="-Xmx2024m -XX:MaxPermSize=256m"

export MAVEN_OPTS="-Xmx2024m -XX:MaxPermSize=256m"

export GRADLE_OPTS="-Xmx2024m -Xms2024m -XX:MaxPermSize=256m"

rm -rf ~/.freerdp/known_hosts

#config for the ssh-agent plugin
zstyle :omz:plugins:ssh-agent agent-forwarding on
zstyle :omz:plugins:ssh-agent identities id_rsa 

PROJECT_PATHS=(~/projects/src)

#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
[[ -s "$HOME/.gvm/bin/gvm-init.sh" ]] && source "$HOME/.gvm/bin/gvm-init.sh"

# this is for homebrew
export PATH=/usr/local/bin:/usr/local/sbin:${PATH}

# for coreutils
p="$(brew --prefix coreutils)"
export PATH="${p}/libexec/gnubin:${PATH}"
export MANPATH="${p}/libexec/gnuman:${MANPATH}"

# for findutils
p="$(brew --prefix findutils)"
export PATH="${p}/bin:${PATH}"
export MANPATH="${p}/share/man:${MANPATH}"

# for gnu-sed
p="$(brew --prefix gnu-sed)"
export PATH="${p}/libexec/gnubin:${PATH}"
export MANPATH="${p}/libexec/gnuman:${MANPATH}"

# for gnu-tar
p="$(brew --prefix gnu-tar)"
export PATH="${p}/libexec/gnubin:${PATH}"
export MANPATH="${p}/libexec/gnuman:${MANPATH}"

# for gnu-which
p="$(brew --prefix gnu-which)"
export PATH="${p}/bin:${PATH}"
export MANPATH="${p}/share/man:${MANPATH}"

# for gawk
p="$(brew --prefix gawk)"
export PATH="${p}/bin:${PATH}"
export MANPATH="${p}/share/man:${MANPATH}"

# for less
p="$(brew --prefix less)"
export PATH="${p}/bin:${PATH}"
export MANPATH="${p}/share/man:${MANPATH}"

PATH=${HOME}/bin:$PATH

# Add appcatalyst
PATH="${PATH}:/opt/vmware/appcatalyst/bin"

bindkey -e
bindkey "\e\e[D" backward-word # alt + <-
bindkey "\e\e[C" forward-word # alt + -> 

#export DOCKER_CERT_PATH=${HOME}/.boot2docker/certs/boot2docker-vm
#export DOCKER_TLS_VERIFY=1
#export DOCKER_HOST=tcp://192.168.59.103:2376
 
export PACKER_CACHE_DIR=${HOME}/.packer

#--------- begin alias ---------#
alias veewee="BUNDLE_GEMFILE=~/projects/src/veewee/Gemfile bundle exec veewee"

#alias dos2unix="todos -d"
#alias unix2dos="todos -u"
alias mtr="mtr --curses"

alias vi=/Applications/MacVim.app/Contents/MacOS/Vim
alias vim=/Applications/MacVim.app/Contents/MacOS/Vim

# copy / move with progress bar
alias rsynccopy="rsync --partial --progress --append --rsh=ssh -r -h "
alias rsyncmove="rsync --partial --progress --append --rsh=ssh -r -h --remove-sent-files"

alias t="top -ocpu -R -F -s 2 -n30"

export GOPATH=/usr/local/opt/go/libexec
export PATH=${PATH}:${GOPATH}/bin
export JMETER_HOME=/usr/local/opt/jmeter

# Java setup
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"

function setjdk() { 
  if [ $# -ne 0 ]; then 
    removeFromPath '/System/Library/Frameworks/JavaVM.framework/Home/bin' 
    if [ -n "${JAVA_HOME+x}" ]; then 
      removeFromPath $JAVA_HOME/bin 
    fi 
    export JAVA_HOME=$(/usr/libexec/java_home -v $@)
    export PATH=$JAVA_HOME/bin:$PATH
  fi 
}

function removeFromPath() {
  export PATH=$(echo "$PATH" | sed -E -e "s;:$1;;" -e "s;$1:?;;") 
}
setjdk 1.8

[ -f "/usr/local/share/zsh/site-functions/_aws" ] && source "/usr/local/share/zsh/site-functions/_aws"

ghpr() { local GIT_BRANCH=$(git symbolic-ref --short HEAD); hub pull-request -b Spantree:develop -h Spantree:${GIT_BRANCH#};}

function docker-enter () {
  boot2docker ssh '[ -f /var/lib/boot2docker/nsenter ] || docker run --rm -v /var/lib/boot2docker/:/target jpetazzo/nsenter'
  boot2docker ssh -t sudo /var/lib/boot2docker/docker-enter "$@"
}

alias gist='gist -p'

export VAGRANT_DEFAULT_PROVIDER=virtualbox
unalias run-help
autoload run-help
export HELPDIR=/usr/local/share/zsh/help

#-------------------------------#

export NVM_DIR=~/.nvm
source "$(brew --prefix nvm)/nvm.sh"

if [ -f "$HOME/.rvm/scripts/rvm" ];
then
    export PATH=$HOME/.rvm/bin:$PATH 
    source "$HOME/.rvm/scripts/rvm"
fi

