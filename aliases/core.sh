# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Common aliases
alias cat=bat --paging=never
#alias ll='exa -l --icons --no-user --group-directories-first  --time-style long-iso'
alias ls='exa -l --group-directories-first --color=auto --git --icons --no-permissions --no-user'
alias ll='exa -lahF --group-directories-first --color=auto --git --icons'


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


alias weather-shakopee="curl wttr.in/Shakopee"
#alias weather="curl wttr.in/55379"

# Specific alias loaders
alias cebartling-github-cd="cd ~/github-sandbox/cebartling"
alias gummi-bear-aliases="source ~/.dotfiles/aliases/gummi-bears.sh"
alias quizzer-aliases="source ~/.dotfiles/aliases/quizzer.sh"
alias saga-pattern-aliases="source ~/.dotfiles/aliases/saga-pattern.sh"
alias swift-aliases="source ~/.dotfiles/aliases/swift.sh"
alias studying-aliases="source ~/.dotfiles/aliases/studying.sh"
alias test-driven-aliases="source ~/.dotfiles/aliases/test-driven.sh"
alias coding-katas-aliases="source ~/.dotfiles/aliases/coding-katas.sh"
alias react-experiments-aliases="source ~/.dotfiles/aliases/react-experiments.sh"
alias testcontainers-experiments-aliases="source ~/.dotfiles/aliases/testcontainers-experiments.sh"
alias remix-experiments-aliases="source ~/.dotfiles/aliases/remix-experiments.sh"
