# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Common aliases
alias cat='bat --paging=never'
alias ls='eza -l --group-directories-first --color=auto --icons --no-permissions --no-user'
alias ll='eza -lahF --group-directories-first --color=auto --icons'
if [[ "$OSTYPE" == darwin* ]]; then
  alias daily-update="brew update && brew upgrade && brew cleanup && claude update"
else
  alias daily-update="sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y autoremove && claude update"
fi

# $EDITOR is resolved in zshrc and may carry a blocking flag (`code --wait`).
# These aliases just open a file, so drop the flags.
_edit="${EDITOR%% *}"
alias zshconfig="$_edit ~/.zshrc"
alias aliases-config="$_edit ~/.dotfiles/aliases/core.sh"
alias ohmyzsh="$_edit ~/.oh-my-zsh"

alias git-log-enhanced="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias hostfile="sudo $_edit /etc/hosts"
unset _edit
alias external-ip="curl https://diagnostic.opendns.com/myip ; echo"
if [[ "$OSTYPE" == darwin* ]]; then
  alias local-ip="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
else
  # iproute2 is standard on Linux; net-tools/ifconfig often isn't installed.
  alias local-ip="ip -brief address show scope global | awk '{ \$1=\$1; print }'"
fi

alias git-config="git config user.name && git config user.email"

# Git configuration
alias config-git-pager="git config --global pager.diff \"less -FX\""
alias personal-add-ssh-key="ssh-add -D && ssh-add -t 24h ~/.ssh/id_ed25519 && ssh-add -l"
alias personal-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris.bartling@gmail.com\""
alias personal-git-setup="personal-add-ssh-key && personal-git-config"

# Docker Compose
alias dc-up="docker compose up -d"
alias dc-down="docker compose down"
alias dc-down-remove-volumes="docker compose down -v --remove-orphans"

# Navigation
alias cebartling-github-cd="cd ~/github-sandbox/cebartling"

# Per-project alias files are auto-loaded by functions/project-aliases.sh
# when you cd into the relevant directory. To register a new project,
# add an entry to PROJECT_ALIAS_MAP in that file.
