#!/bin/zsh
# Install (or update) the NetBird GUI app on macOS.
# The actual package list lives in $DOTFILES/Brewfile.netbird.
# Requires sudo (the cask runs a privileged installer.sh), so this is
# opt-in rather than part of bootstrap.sh.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
source "$DOTFILES/scripts/macOS/lib/brew_trust.sh"

autoload colors
colors

echo $fg[cyan]Installing NetBird GUI app on macOS via brew bundle...$reset_color

brew update
brew_trust_taps "$DOTFILES/Brewfile.netbird"
brew bundle --file="$DOTFILES/Brewfile.netbird"

echo $fg[cyan]Finished installing NetBird GUI app on macOS!$reset_color
