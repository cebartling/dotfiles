# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Common aliases
alias ll='exa -l --icons --no-user --group-directories-first  --time-style long-iso'
alias weather="curl wttr.in/55379"
alias zshconfig="code ~/.zshrc"
alias aliases-config="code ~/.dotfiles/aliases/core.sh"
alias ohmyzsh="code ~/.oh-my-zsh"
alias java8="sdk use java 8.0.232.hs-adpt && java -version"
alias java11="sdk use java 11.0.11.hs-adpt && java -version"
alias java12="sdk use java 12.0.1.hs-adpt && java -version"
alias java13="sdk use java 13.0.2.hs-adpt && java -version"
alias java15="sdk use java 15.0.2.hs-adpt && java -version"
alias nuget="mono /usr/local/bin/nuget.exe"
alias yarn-up="yarn upgrade-interactive --latest"

# Specific alias loaders
alias cebartling-github-cd="cd ~/github-sandbox/cebartling"
alias gummi-bear-aliases="source ~/.dotfiles/aliases/gummi-bears.sh"
alias quizzer-aliases="source ~/.dotfiles/aliases/quizzer.sh"
alias saga-pattern-aliases="source ~/.dotfiles/aliases/saga-pattern.sh"
alias swift-aliases="source ~/.dotfiles/aliases/swift.sh"
alias studying-aliases="source ~/.dotfiles/aliases/studying.sh"
alias test-driven-aliases="source ~/.dotfiles/aliases/test-driven.sh"
alias code-katas-aliases="source ~/.dotfiles/aliases/code-katas.sh"
