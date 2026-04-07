#!/bin/zsh
# Symlink dotfiles into place. Idempotent and safe — any existing
# non-symlink target is backed up to <file>.backup.<timestamp>
# before being replaced. Re-running on a system that's already
# linked is a no-op.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
TS="$(date +%Y%m%d-%H%M%S)"

autoload colors
colors

# link <source> <target>
# - source: file inside $DOTFILES
# - target: absolute path under $HOME
link() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo $fg[red]"missing source: $src"$reset_color
    return 1
  fi

  # Already correctly linked? Nothing to do.
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo $fg[green]"ok"$reset_color"   $dst -> $src"
    return 0
  fi

  # Existing file/dir/symlink that points elsewhere — back it up.
  if [[ -e "$dst" || -L "$dst" ]]; then
    local backup="${dst}.backup.${TS}"
    echo $fg[yellow]"backup"$reset_color" $dst -> $backup"
    mv "$dst" "$backup"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo $fg[cyan]"link"$reset_color"   $dst -> $src"
}

echo $fg[cyan]"Linking dotfiles from $DOTFILES..."$reset_color
echo

link "$DOTFILES/zshrc"                       "$HOME/.zshrc"
link "$DOTFILES/configurations/starship.toml" "$HOME/.config/starship.toml"

echo
echo $fg[cyan]"Done."$reset_color
