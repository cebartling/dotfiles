#!/bin/zsh
# Install (or update) AI / coding agent macOS packages.
# The actual package list lives in $DOTFILES/Brewfile.ai.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

autoload colors
colors

echo $fg[cyan]Installing AI tools on macOS via brew bundle...$reset_color

brew update
brew bundle --file="$DOTFILES/Brewfile.ai"

echo $fg[cyan]Finished installing AI tools on macOS!$reset_color
