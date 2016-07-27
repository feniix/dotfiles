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
adb
ant
#aws
battery
brew
brew-cask
bundler
capistrano
catimg
coffee
command-not-found
common-aliases
colored-man
colorize
debian
docker
encode64
extract
fabric
git
git-flow
github
gitignore
gem
gnu-utils
#gpg-agent
gradle
grails
history-substring-search
iwhois
jruby
knife
last-working-dir
lein
mercurial
mvn
node
npm
nvm
pip
pj
pylint
python
rbfu
rsync
ruby
#rvm
screen
ssh-agent
sublime
sudo
svn
systemadmin
thor
urltools
vagrant
virtualenv
vundle
zsh_reload
)

source $ZSH/oh-my-zsh.sh

export DEBFULLNAME="Sebastian Otaegui"
export DEBEMAIL="feniix@gmail.com"

# history settings
setopt INC_APPEND_HISTORY AUTO_REMOVE_SLASH
setopt LIST_TYPES LONG_LIST_JOBS HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE
export EDITOR=vim
HISTSIZE=10000
SAVEHIST=10000

#AMAZON EC2
export EC2_AMITOOL_HOME="/home/otaeguis/.linuxbrew/Cellar/ec2-ami-tools/1.5.6/libexec"
export EC2_HOME="/home/otaeguis/.linuxbrew/Cellar/ec2-api-tools/1.7.3.0/libexec"

alias dquilt="quilt --quiltrc=${HOME}/.quiltrc-dpkg"

export ANT_OPTS="-Xmx2024m -XX:MaxPermSize=256m"

export MAVEN_OPTS="-Xmx2024m -XX:MaxPermSize=256m"

export GRADLE_OPTS="-Xmx2024m -Xms2024m -XX:MaxPermSize=256m"

rm -rf ~/.freerdp/known_hosts

#config for the ssh-agent plugin
zstyle :omz:plugins:ssh-agent agent-forwarding on
zstyle :omz:plugins:ssh-agent identities id_rsa

PROJECT_PATHS=(~/src)

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
[[ -s $HOME/.sdkman/bin/sdkman-init.sh ]] && source $HOME/.sdkman/bin/sdkman-init.sh

PATH=$HOME/bin:$PATH

bindkey -e
bindkey '^[[1;9C' forward-word
bindkey '^[[1;9D' backward-word

#export DOCKER_CERT_PATH=${HOME}/.boot2docker/certs/boot2docker-vm
#export DOCKER_TLS_VERIFY=1
#export DOCKER_HOST=tcp://192.168.59.103:2376

export PACKER_CACHE_DIR=${HOME}/.packer

#export GOPATH=/home/otaeguis/.linuxbrew/opt/go/libexec
#export PATH=$PATH:/home/otaeguis/.linuxbrew/opt/go/libexec/bin

#--------- begin alias ---------#
alias veewee="BUNDLE_GEMFILE=~/projects/src/veewee/Gemfile bundle exec veewee"

#alias dos2unix="todos -d"
#alias unix2dos="todos -u"
alias mtr="mtr --curses"

# copy / move with progress bar
alias rsynccopy="rsync --partial --progress --append --rsh=ssh -r -h "
alias rsyncmove="rsync --partial --progress --append --rsh=ssh -r -h --remove-sent-files"

# Java setup
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"

source "${HOME}/.linuxbrew/share/zsh/site-functions/_aws"

alias gist='gist -p'

ghpr() {local GIT_BRANCH=$(git symbolic-ref --short HEAD); hub pull-request -b Spantree:develop -h Spantree:${GIT_BRANCH#};}

#-------------------------------#
export PATH="$HOME/.linuxbrew/bin:$PATH"
export PATH="$PATH:/opt/packer"
export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"
export PATH=$HOME/.cabal/bin:$PATH

export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

export PATH=$HOME/.rbenv/bin:$PATH
eval "$(rbenv init -)"


# The next line updates PATH for the Google Cloud SDK.
source '/home/otaeguis/google-cloud-sdk/path.zsh.inc'

# The next line enables shell command completion for gcloud.
source '/home/otaeguis/google-cloud-sdk/completion.zsh.inc'
