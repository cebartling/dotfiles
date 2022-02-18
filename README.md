# dotfiles
ZShell configuration

## Using this repository

1. Clone this repository to **$HOME/.dotfiles** directory: `git clone git@github.com:cebartling/dotfiles.git $HOME/.dotfiles`
1. Edit your `$HOME/.zshrc` file:

    ```zsh
    # If you come from bash you might have to change your $PATH.
    # export PATH=$HOME/bin:/usr/local/bin:$PATH

    # Path to your oh-my-zsh installation.
    export ZSH="$HOME/.oh-my-zsh"
    export DOTFILES="$HOME/.dotfiles"

    source $DOTFILES/oh-my-zsh/core.sh
    source $ZSH/oh-my-zsh.sh

    source $DOTFILES/functions/core.sh

    # User configuration

    # export MANPATH="/usr/local/man:$MANPATH"

    # You may need to manually set your language environment
    # export LANG=en_US.UTF-8

    # Preferred editor for local and remote sessions
    # if [[ -n $SSH_CONNECTION ]]; then
    #   export EDITOR='vim'
    # else
    #   export EDITOR='mvim'
    # fi

    # Compilation flags
    # export ARCHFLAGS="-arch x86_64"

    source $DOTFILES/aliases/core.sh

    source $DOTFILES/paths/core.sh

    source $DOTFILES/runtimes/nvm.sh
    source $DOTFILES/runtimes/sdkman.sh
    source $DOTFILES/runtimes/rbenv.sh
    source $DOTFILES/runtimes/pyenv.sh
    source $DOTFILES/runtimes/poetry.sh

    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

    export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

    ```
1. Restart your terminal and enjoy!
