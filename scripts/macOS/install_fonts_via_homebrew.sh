#!/bin/zsh

echo "Installing Nerd Fonts..."

brew tap homebrew/cask-fonts
brew install --cask font-3270-nerd-font
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-liberation-nerd-font
brew install --cask font-hack-nerd-font

echo "Finished installing Nerd Fonts!"
