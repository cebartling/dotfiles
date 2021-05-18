# dotfiles
ZShell configuration


## Edit your .zshrc file

```shell
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

export DOTFILES="$HOME/.dotfiles"

source $DOTFILES/oh-my-zsh/core.sh

source $ZSH/oh-my-zsh.sh

source $DOTFILES/functions/core.sh
```

### Adding NVM support

```shell
source $DOTFILES/runtimes/nvm.sh
```
### Adding SDKMAN! support

```shell
source $DOTFILES/runtimes/sdkman.sh
```