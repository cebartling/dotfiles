#!/bin/zsh
# Install (or update) cloud management tooling on macOS.
# The actual package list lives in $DOTFILES/Brewfile.cloud.
# Kept separate from bootstrap because not every Mac manages cloud infra.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
source "$DOTFILES/scripts/macOS/lib/brew_trust.sh"

autoload colors
colors

echo $fg[cyan]Installing cloud management tools on macOS via brew bundle...$reset_color

brew update
brew_trust_taps "$DOTFILES/Brewfile.cloud"
brew bundle --file="$DOTFILES/Brewfile.cloud"

echo $fg[cyan]Finished installing cloud management tools on macOS!$reset_color
