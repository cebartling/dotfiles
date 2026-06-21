#!/bin/zsh
# Install (or update) the Tailscale GUI app on macOS.
# The actual package list lives in $DOTFILES/Brewfile.tailscale.
# Requires sudo (the cask runs a .pkg installer), so this is opt-in
# rather than part of bootstrap.sh.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
source "$DOTFILES/scripts/macOS/lib/brew_trust.sh"

autoload colors
colors

echo $fg[cyan]Installing Tailscale GUI app on macOS via brew bundle...$reset_color

brew update
brew_trust_taps "$DOTFILES/Brewfile.tailscale"
brew bundle --file="$DOTFILES/Brewfile.tailscale"

echo $fg[cyan]Finished installing Tailscale GUI app on macOS!$reset_color
