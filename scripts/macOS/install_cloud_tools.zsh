#!/bin/zsh
# Install (or update) cloud management tooling on macOS.
# The actual package list lives in $DOTFILES/Brewfile.cloud.
# Kept separate from bootstrap because not every Mac manages cloud infra.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

autoload colors
colors

echo $fg[cyan]Installing cloud management tools on macOS via brew bundle...$reset_color

brew update
brew bundle --file="$DOTFILES/Brewfile.cloud"

echo $fg[cyan]Finished installing cloud management tools on macOS!$reset_color
