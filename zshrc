# =============================================================
#  zshrc — managed by cebartling/dotfiles
#  Symlinked into place by scripts/macOS/link.zsh (macOS) or
#  scripts/Ubuntu/link.sh (Linux).
#  Do NOT edit ~/.zshrc directly on a managed machine — edit this
#  file in $DOTFILES/zshrc and `git pull` everywhere else.
#  This file is shared by macOS and Linux: every platform-specific
#  branch below must be guarded, so a pull is a no-op on the other.
#  Per-machine overrides go in ~/.zshrc.local (gitignored).
# =============================================================

# ----- Core env -----
export DOTFILES="$HOME/.dotfiles"
export ZSH="$HOME/.oh-my-zsh"
# First editor that's actually installed wins, so $EDITOR is never a
# command that doesn't exist (a Linux box generally has no `code`).
for _ed in 'code --wait' 'cursor --wait' 'zed --wait' nvim vim nano vi; do
  (( $+commands[${_ed%% *}] )) && { export EDITOR="$_ed"; break }
done
unset _ed
: ${EDITOR:=vi}
export VISUAL="$EDITOR"
export LANG=en_US.UTF-8

# ----- Homebrew (detect prefix; supports /opt/homebrew, /usr/local, ~/homebrew,
#       and linuxbrew — no-op on a Linux box installed from apt) -----
for _brew_candidate in /opt/homebrew/bin/brew /usr/local/bin/brew \
                       "$HOME/homebrew/bin/brew" /home/linuxbrew/.linuxbrew/bin/brew; do
  if [ -x "$_brew_candidate" ]; then
    eval "$("$_brew_candidate" shellenv)"
    break
  fi
done
unset _brew_candidate

# ----- PATH (consolidated, deduped) -----
if [[ "$OSTYPE" == darwin* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi
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
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source $ZSH/oh-my-zsh.sh
else
  print -u2 "zshrc: oh-my-zsh not found at $ZSH — install it with:"
  print -u2 "  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
fi

# ----- Dotfiles helpers -----
source $DOTFILES/functions/core.sh
source $DOTFILES/aliases/core.sh
source $DOTFILES/paths/core.sh
source $DOTFILES/functions/project-aliases.sh

# ----- Lazy runtimes (huge startup speedup) -----
# nvm: load on first use of nvm/node/npm/npx.
# macOS gets nvm from the Homebrew formula ($HOMEBREW_PREFIX/opt/nvm);
# Linux installs nvm proper into $NVM_DIR. Resolve whichever exists — and
# if NEITHER does, define no wrappers at all: a wrapper whose nvm.sh is
# missing would unset itself and then recurse into a command that isn't
# there, so plain `node` from the system package would break.
# Under Claude Code we eager-load instead — Claude Code's shell snapshot
# captures the wrappers but drops the underscore-prefixed _nvm_load helper
# they depend on, so subprocesses sourcing the snapshot infinite-loop on
# FUNCNEST when invoking npx/npm/node.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
_nvm_sh=""
_nvm_completion=""
for _nvm_prefix in "${HOMEBREW_PREFIX}/opt/nvm" "$NVM_DIR"; do
  [ -s "$_nvm_prefix/nvm.sh" ] || continue
  _nvm_sh="$_nvm_prefix/nvm.sh"
  # Homebrew ships completion under etc/, nvm's own installer at the root.
  for _nvm_comp_candidate in \
        "$_nvm_prefix/etc/bash_completion.d/nvm" \
        "$_nvm_prefix/bash_completion"; do
    [ -s "$_nvm_comp_candidate" ] && { _nvm_completion="$_nvm_comp_candidate"; break }
  done
  break
done
unset _nvm_prefix _nvm_comp_candidate

if [[ -n "$_nvm_sh" ]]; then
  if [[ -n "$CLAUDECODE" ]]; then
    \. "$_nvm_sh"
    [[ -n "$_nvm_completion" ]] && \. "$_nvm_completion"
  else
    _nvm_load() {
      unset -f nvm node npm npx _nvm_load
      \. "$_nvm_sh"
      [[ -n "$_nvm_completion" ]] && \. "$_nvm_completion"
    }
    nvm()  { _nvm_load; nvm  "$@"; }
    node() { _nvm_load; node "$@"; }
    npm()  { _nvm_load; npm  "$@"; }
    npx()  { _nvm_load; npx  "$@"; }
  fi
fi

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
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ----- zoxide (frecency cd: `z partial-name`) -----
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ----- direnv (per-directory env from .envrc; `direnv allow` to trust one) -----
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# ----- zsh plugins (autosuggestions, then syntax-highlighting LAST) -----
# Homebrew keeps these under $HOMEBREW_PREFIX/share; the Debian/Ubuntu
# packages install them under /usr/share. Source the first hit, and keep
# syntax-highlighting last — it has to wrap everything before it.
for _zsh_plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  for _zsh_plugin_dir in "${HOMEBREW_PREFIX}/share" /usr/share /usr/local/share; do
    if [ -f "$_zsh_plugin_dir/$_zsh_plugin/$_zsh_plugin.zsh" ]; then
      source "$_zsh_plugin_dir/$_zsh_plugin/$_zsh_plugin.zsh"
      break
    fi
  done
done
unset _zsh_plugin _zsh_plugin_dir

# libpq is keg-only on Homebrew; only prepend it where it exists.
[[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/libpq/bin" ]] && \
  path=("${HOMEBREW_PREFIX:-/opt/homebrew}/opt/libpq/bin" $path)

# ----- Per-machine overrides (untracked, optional) -----
# Docker Desktop's installer appends its own `fpath=(... ); compinit` block
# here on first run. Don't keep it: $HOME/.docker/completions is already on
# fpath above and the single `compinit -C` (line 98) picks it up. A second
# compinit just re-runs compaudit/compdump on every shell.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
