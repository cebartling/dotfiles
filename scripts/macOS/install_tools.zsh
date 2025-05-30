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
brew install derailed/k9s/k9s
brew install 1password-cli
brew install fastfetch
brew install direnv
brew install caddy

echo $fg[cyan]Installing Kubernetes tools on macOS...$reset_color

brew install kubernetes-cli
brew tap sozercan/kubectl-ai https://github.com/sozercan/kubectl-ai
brew install kubectl-ai


gh extension install dlvhdr/gh-dash

echo $fg[cyan]Finished installing essential tools on macOS!$reset_color
