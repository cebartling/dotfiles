#!/bin/zsh
# Install (or update) Apple-platform (iOS/iPadOS/macOS) dev tools.
# The actual package list lives in $DOTFILES/Brewfile.apple.
# Kept separate from bootstrap because not every Mac does
# Swift/Xcode development.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

autoload colors
colors

echo $fg[cyan]Installing Apple-platform dev tools on macOS via brew bundle...$reset_color

brew update
brew bundle --file="$DOTFILES/Brewfile.apple"

echo $fg[cyan]Finished installing Apple-platform dev tools on macOS!$reset_color
