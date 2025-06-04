#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Installing essential tools on macOS...$reset_color

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
brew install --cask wave
brew install --cask obsidian
brew install --cask postman
brew install --cask zed
brew install --cask chatgpt
brew install --cask claude
brew install derailed/k9s/k9s
brew install 1password-cli
brew install fastfetch
brew install direnv
brew install caddy

# Doing MongoDB? Uncomment the following line for MongoDB Compass
# brew install --cask mongodb-compass

echo $fg[cyan]Finished installing essential tools on macOS!$reset_color
