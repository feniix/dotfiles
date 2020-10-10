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
colored-man-pages
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

complete () {
	emulate -L zsh
	local args void cmd print remove
	args=("$@")
	zparseopts -D -a void o: A: G: W: C: F: P: S: X: a b c d e f g j k u v p=print r=remove
	if [[ -n $print ]]
	then
		printf 'complete %2$s %1$s\n' "${(@kv)_comps[(R)_bash*]#* }"
	elif [[ -n $remove ]]
	then
		for cmd
		do
			unset "_comps[$cmd]"
		done
	else
		compdef _bash_complete\ ${(j. .)${(q)args[1,-1-$#]}} "$@"
	fi
}

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

export GRADLE_OPTS="-Xmx2024m -Xms2024m "

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

export PATH=~/go/bin:${PATH}

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
setjdk 11

[[ -f "/usr/local/bin/aws_completer" ]] && complete -C '/usr/local/bin/aws_completer' aws
export AWS_PAGER=""

alias gist='gist -p'

export VAGRANT_DEFAULT_PROVIDER=virtualbox
unalias run-help
autoload run-help
export HELPDIR=/usr/local/share/zsh/help

#-------------------------------#

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

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

asdf_unload() {
  removeFromPath /Users/otaegui/.asdf/shims
  removeFromPath /usr/local/opt/asdf/bin
}

asdf_load() {
  source /usr/local/opt/asdf/asdf.sh
  source /usr/local/etc/bash_completion.d/asdf.bash
}
asdf_load

source <(kubectl completion zsh)
source <(kops completion zsh)
#source ~/sbin/kubectl-completion
#source ~/sbin/kops-completion

eval "$(direnv hook zsh)"

export MONO_GAC_PREFIX=/usr/local
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

export PATH="/usr/local/opt/curl-openssl/bin:$PATH"
#export PATH="/usr/local/opt/php@7.3/bin:$PATH"
#export PATH="/usr/local/opt/php@7.3/sbin:$PATH"
export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gnu-getopt/bin:$PATH"

export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"

# this is needed to load the AWS credentials in some go apps that use the aws
# sdk
export AWS_SDK_LOAD_CONFIG=1

export KUBECONFIG=$HOME/.kube/config
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH=$HOME/.linkerd2/bin:$PATH
export PATH="/usr/local/opt/node@12/bin:$PATH"
export PATH="/usr/local/opt/python/libexec/bin:$PATH"

source "$HOME/.sdkman/bin/sdkman-init.sh"

# The next line updates PATH for the Google Cloud SDK.
if [ -f /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc ]; then
  source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc
fi

# The next line enables shell command completion for gcloud.
if [ -f /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc ]; then
  source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc
fi

export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/usr/local/opt/openssl@1.1"

#zprof


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
#__conda_setup="$('/usr/local/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
#if [ $? -eq 0 ]; then
#    eval "$__conda_setup"
#else
#    if [ -f "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
#        . "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh"
#    else
#        export PATH="/usr/local/Caskroom/miniconda/base/bin:$PATH"
#    fi
#fi
#unset __conda_setup
# <<< conda initialize <<<

function list() {
  case $1 in
    projects)
      gcloud projects list --format 'table(name:sort=1,projectId,parent.id:label=Parent)'
      ;;
    *)
      ;;
  esac
}

###_begin_ttt_install_block_###
export PATH=/Users/otaegui/.ttt_home:$PATH
###_end_ttt_install_block_###

