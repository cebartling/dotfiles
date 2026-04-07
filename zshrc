# =============================================================
#  zshrc — managed by cebartling/dotfiles
#  Symlinked into place by scripts/macOS/link.zsh.
#  Do NOT edit ~/.zshrc directly on a managed Mac — edit this
#  file in $DOTFILES/zshrc and `git pull` everywhere else.
#  Per-machine overrides go in ~/.zshrc.local (gitignored).
# =============================================================

# ----- Core env -----
export DOTFILES="$HOME/.dotfiles"
export ZSH="$HOME/.oh-my-zsh"
export EDITOR='code --wait'
export VISUAL="$EDITOR"
export LANG=en_US.UTF-8

# ----- PATH (consolidated, deduped) -----
export PNPM_HOME="$HOME/Library/pnpm"
typeset -U path                              # automatic dedupe
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$PNPM_HOME"
  $path
)

# ----- History -----
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE \
       HIST_REDUCE_BLANKS INC_APPEND_HISTORY EXTENDED_HISTORY \
       HIST_VERIFY

# ----- Shell options -----
setopt AUTO_CD EXTENDED_GLOB NO_BEEP INTERACTIVE_COMMENTS

# ----- oh-my-zsh (theme is empty; starship handles the prompt) -----
source $DOTFILES/oh-my-zsh/core.sh
source $ZSH/oh-my-zsh.sh

# ----- Dotfiles helpers -----
source $DOTFILES/functions/core.sh
source $DOTFILES/aliases/core.sh
source $DOTFILES/paths/core.sh
source $DOTFILES/functions/project-aliases.sh

# ----- Lazy runtimes (huge startup speedup) -----
# nvm: load on first use of nvm/node/npm/npx
export NVM_DIR="$HOME/.nvm"
_nvm_load() {
  unset -f nvm node npm npx _nvm_load
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
}
nvm()  { _nvm_load; nvm  "$@"; }
node() { _nvm_load; node "$@"; }
npm()  { _nvm_load; npm  "$@"; }
npx()  { _nvm_load; npx  "$@"; }

# sdkman: load on first use of sdk
export SDKMAN_DIR="$HOME/.sdkman"
sdk() {
  unset -f sdk
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
  sdk "$@"
}

# Eager (cheap) runtime hooks
source $DOTFILES/runtimes/claude.sh

# ----- fpath additions (must be BEFORE compinit) -----
fpath=(
  "$HOME/.zsh/completion"
  "$HOME/.docker/completions"
  $fpath
)

# ----- Completion (single compinit, after all fpath mods) -----
autoload -Uz compinit
compinit -C

# ----- Integrations -----
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# ----- Prompt -----
unset RPROMPT
eval "$(starship init zsh)"

# ----- zsh plugins (autosuggestions, then syntax-highlighting LAST) -----
[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ----- Per-machine overrides (untracked, optional) -----
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
