#!/bin/sh

echo "Installing essentials tools on macOS..."

brew update
brew install vale
brew install openssl
brew install git
brew install curl
brew install starship
brew install bat
brew install eza
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
brew install devutils
brew install gh
brew install awslogs
brew install dust
brew install hyperfine
brew install --cask warp
brew install derailed/k9s/k9s

gh extension install dlvhdr/gh-dash

echo "Finished installing essentials tools on macOS!"
