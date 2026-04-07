# dotfiles
ZShell configuration

## Using this repository

1. Clone this repository to **$HOME/.dotfiles** directory: `git clone git@github.com:cebartling/dotfiles.git $HOME/.dotfiles`
1. Edit your `$HOME/.zshrc` file:

    ```zsh
    # Path to your oh-my-zsh installation.
    export ZSH="$HOME/.oh-my-zsh"
    export DOTFILES="$HOME/.dotfiles"

    source $DOTFILES/oh-my-zsh/core.sh
    source $ZSH/oh-my-zsh.sh

    source $DOTFILES/functions/core.sh
    source $DOTFILES/aliases/core.sh
    source $DOTFILES/paths/core.sh

    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
    fpath=($fpath ~/.zsh/completion)
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

    # Language runtimes
    source $DOTFILES/runtimes/sdkman.sh
    source $DOTFILES/runtimes/nvm-homebrew.sh
    #source $DOTFILES/runtimes/rbenv.sh
    #source $DOTFILES/runtimes/pyenv.sh
    #source $DOTFILES/runtimes/poetry.sh

    # AI tooling
    source $DOTFILES/runtimes/claude.sh

    eval "$(starship init zsh)"
    ```
1. Restart your terminal and enjoy!
