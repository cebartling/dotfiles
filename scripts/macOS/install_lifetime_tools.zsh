#!/bin/zsh
# Install (or update) the Life Time work laptop's macOS packages.
# The actual package list lives in $DOTFILES/Brewfile.lifetime.
# Standalone manifest: on that laptop it replaces the main Brewfile,
# so run this instead of install_tools.zsh / bootstrap's brew bundle.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
source "$DOTFILES/scripts/macOS/lib/brew_trust.sh"

autoload colors
colors

echo $fg[cyan]Installing Life Time laptop tools on macOS via brew bundle...$reset_color

brew update
brew_trust_taps "$DOTFILES/Brewfile.lifetime"
brew bundle --file="$DOTFILES/Brewfile.lifetime"

echo $fg[cyan]Finished installing Life Time laptop tools on macOS!$reset_color
