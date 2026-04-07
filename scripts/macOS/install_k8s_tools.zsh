#!/bin/zsh
# Install (or update) Kubernetes-specific macOS packages.
# The actual package list lives in $DOTFILES/Brewfile.k8s.

set -e

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

autoload colors
colors

echo $fg[cyan]Installing Kubernetes tools on macOS via brew bundle...$reset_color

brew update
brew bundle --file="$DOTFILES/Brewfile.k8s"

echo $fg[cyan]Finished installing Kubernetes tools on macOS!$reset_color
