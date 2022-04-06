#!/bin/zsh

echo "Installing essentials tools on macOS..."

brew update
brew install openssl
brew install git
brew install curl
brew install starship
brew install bat
brew install exa
brew install ripgrep
brew install httpie
brew install procs
brew install dog
brew install fx
brew install fzf
brew install tmux
brew install cheat
brew install figlet
brew install lolcat
brew install gh
gh extension install dlvhdr/gh-dash

echo "Finished installing essentials tools on macOS!"
