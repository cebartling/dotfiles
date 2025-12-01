# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

ssh-add -D && ssh-add ~/.ssh/id_ed25519 && ssh-add -l
git config user.name "Christopher Bartling" && git config user.email "chris.bartling@gmail.com"

# Common aliases
alias cat=bat --paging=never
#alias ll='eza -l --icons --no-user --group-directories-first  --time-style long-iso'
alias ls='eza -l --group-directories-first --color=auto --icons --no-permissions --no-user'
alias ll='eza -lahF --group-directories-first --color=auto --icons'

alias zshconfig="code ~/.zshrc"
alias aliases-config="code ~/.dotfiles/aliases/core.sh"
alias ohmyzsh="code ~/.oh-my-zsh"
alias java8="sdk use java 8.0.232.hs-adpt && java -version"
alias java11="sdk use java 11.0.11.hs-adpt && java -version"
alias java12="sdk use java 12.0.1.hs-adpt && java -version"
alias java13="sdk use java 13.0.2.hs-adpt && java -version"
alias java15="sdk use java 15.0.2.hs-adpt && java -version"
alias java17="sdk use java 17.0.2-tem && java -version"
alias nuget="mono /usr/local/bin/nuget.exe"
alias yarn-up="yarn upgrade-interactive --latest"

alias git-log-enhanced="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias hostfile="sudo code /etc/hosts"
alias external-ip="curl https://diagnostic.opendns.com/myip ; echo"
alias local-ip="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
alias git-config="git config user.name && git config user.email"

alias git-set-ssh-key="ssh-add -D && ssh-add -t 24h ~/.ssh/id_ed25519 && ssh-add -l"
alias git-set-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris.bartling@gmail.com\""

alias weather-shakopee="curl https://wttr.in/Shakopee\?u"
#alias weather="curl wttr.in/55379?u"

# Git configuration
alias config-git-pager="git config --global pager.diff \"less -FX\""
alias personal-add-ssh-key="ssh-add -D && ssh-add ~/.ssh/id_ed25519 && ssh-add -l"
alias personal-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris.bartling@gmail.com\""

# Specific alias loaders

alias lifetime-aliases="source ~/.dotfiles/aliases/lifetime.sh"



alias aws-cdk-experiments-aliases="source ~/.dotfiles/aliases/aws-cdk-experiments.sh"
alias aws-explorer-aliases="source ~/.dotfiles/aliases/aws-explorer.sh"
alias azure-experiments-aliases="source ~/.dotfiles/aliases/azure-experiments.sh"
alias cebartling-github-cd="cd ~/github-sandbox/cebartling"
alias coding-katas-aliases="source ~/.dotfiles/aliases/coding-katas.sh"
alias d3-experiments-aliases="source ~/.dotfiles/aliases/d3-experiments.sh"
alias gummi-bear-aliases="source ~/.dotfiles/aliases/gummi-bears.sh"
alias joy-of-react-aliases="source ~/.dotfiles/aliases/joy-of-react.sh"
alias kubernetes-experiments-aliases="source ~/.dotfiles/aliases/kubernetes-experiments.sh"
# alias localstack-experiments-aliases="source ~/.dotfiles/aliases/localstack-experiments.sh"
alias pneuma-aliases="source ~/.dotfiles/aliases/pneuma.sh"
alias quizzer-aliases="source ~/.dotfiles/aliases/quizzer.sh"
alias react-experiments-aliases="source ~/.dotfiles/aliases/react-experiments.sh"
alias remix-experiments-aliases="source ~/.dotfiles/aliases/remix-experiments.sh"
alias saga-pattern-aliases="source ~/.dotfiles/aliases/saga-pattern.sh"
alias swift-aliases="source ~/.dotfiles/aliases/swift.sh"
alias studying-aliases="source ~/.dotfiles/aliases/studying.sh"
alias test-driven-aliases="source ~/.dotfiles/aliases/test-driven.sh"
alias testcontainers-experiments-aliases="source ~/.dotfiles/aliases/testcontainers-experiments.sh"
alias tauri-experiments-aliases="source ~/.dotfiles/aliases/tauri-experiments.sh"
alias real-python-aliases="source ~/.dotfiles/aliases/real-python.sh"
alias remix-ecommerce-aliases="source ~/.dotfiles/aliases/remix-ecommerce.sh"
alias replay-forensics-aliases="source ~/.dotfiles/aliases/replay-forensics.sh"
alias tailwind-css-experiments-aliases="source ~/.dotfiles/aliases/tailwind-css-experiments.sh"
alias kafka-experiments-aliases="source ~/.dotfiles/aliases/kafka-experiments.sh"
alias spring-boot-spikes-aliases="source ~/.dotfiles/aliases/spring-boot-spikes.sh"
alias deck-gl-spikes-aliases="source ~/.dotfiles/aliases/deck-gl-spikes.sh"
