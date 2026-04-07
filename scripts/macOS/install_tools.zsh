#!/bin/zsh
# Install (or update) all macOS packages from the canonical Brewfile.
# The actual package list lives in $DOTFILES/Brewfile.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

autoload colors
colors

echo $fg[cyan]Installing essential tools on macOS via brew bundle...$reset_color

brew update
brew bundle --file="$DOTFILES/Brewfile"

echo $fg[cyan]Finished installing essential tools on macOS!$reset_color
