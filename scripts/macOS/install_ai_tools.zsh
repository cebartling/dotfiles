#!/bin/zsh
# Install (or update) AI / coding agent macOS packages.
# The actual package list lives in $DOTFILES/Brewfile.ai.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
source "$DOTFILES/scripts/macOS/lib/brew_trust.sh"

autoload colors
colors

echo $fg[cyan]Installing AI tools on macOS via brew bundle...$reset_color

brew update
brew_trust_taps "$DOTFILES/Brewfile.ai"
brew bundle --file="$DOTFILES/Brewfile.ai"

echo $fg[cyan]Finished installing AI tools on macOS!$reset_color
