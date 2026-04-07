#!/bin/zsh
# Install (or update) the Tailscale GUI app on macOS.
# The actual package list lives in $DOTFILES/Brewfile.tailscale.
# Requires sudo (the cask runs a .pkg installer), so this is opt-in
# rather than part of bootstrap.sh.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

autoload colors
colors

echo $fg[cyan]Installing Tailscale GUI app on macOS via brew bundle...$reset_color

brew update
brew bundle --file="$DOTFILES/Brewfile.tailscale"

echo $fg[cyan]Finished installing Tailscale GUI app on macOS!$reset_color
