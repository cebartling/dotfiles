#!/bin/zsh
# Install (or update) Apple-platform (iOS/iPadOS/macOS) dev tools.
# The actual package list lives in $DOTFILES/Brewfile.apple.
# Kept separate from bootstrap because not every Mac does
# Swift/Xcode development.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
source "$DOTFILES/scripts/macOS/lib/brew_trust.sh"

autoload colors
colors

echo $fg[cyan]Installing Apple-platform dev tools on macOS via brew bundle...$reset_color

brew update
brew_trust_taps "$DOTFILES/Brewfile.apple"
brew bundle --file="$DOTFILES/Brewfile.apple"

echo $fg[cyan]Finished installing Apple-platform dev tools on macOS!$reset_color
