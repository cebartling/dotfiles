#!/usr/bin/env bash
# link.sh — symlink dotfiles into place on Linux. Idempotent and safe:
# any existing non-symlink target is backed up to <file>.backup.<timestamp>
# before being replaced. Re-running on a linked system is a no-op.
#
# The Linux counterpart to scripts/macOS/link.zsh. The cmux links are
# omitted (macOS app, one of them targets ~/Library/Application Support),
# and the ghostty config is linked only if ghostty is actually installed.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
TS="$(date +%Y%m%d-%H%M%S)"

C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'
C_CYN=$'\033[36m'; C_RST=$'\033[0m'

# link <source> <target>
#   source: file inside $DOTFILES
#   target: absolute path under $HOME
link() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "${C_RED}missing source: $src${C_RST}"
    return 1
  fi

  # Already correctly linked? Nothing to do.
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "${C_GRN}ok${C_RST}     $dst -> $src"
    return 0
  fi

  # Existing file/dir/symlink that points elsewhere — back it up.
  if [[ -e "$dst" || -L "$dst" ]]; then
    local backup="${dst}.backup.${TS}"
    echo "${C_YEL}backup${C_RST} $dst -> $backup"
    mv "$dst" "$backup"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "${C_CYN}link${C_RST}   $dst -> $src"
}

echo "${C_CYN}Linking dotfiles from $DOTFILES...${C_RST}"
echo

link "$DOTFILES/zshrc"                        "$HOME/.zshrc"
link "$DOTFILES/configurations/starship.toml" "$HOME/.config/starship.toml"

# The one tracked executable meant to land on $PATH. ~/.local/bin is already
# on $path via zshrc; link() creates the directory if it is missing.
link "$DOTFILES/scripts/Ubuntu/wlheadless-run" "$HOME/.local/bin/wlheadless-run"

if command -v ghostty >/dev/null 2>&1; then
  link "$DOTFILES/configurations/ghostty/config" "$HOME/.config/ghostty/config"
else
  echo "${C_YEL}skip${C_RST}   ghostty config (ghostty not installed)"
fi

echo
echo "${C_CYN}Done.${C_RST}"
