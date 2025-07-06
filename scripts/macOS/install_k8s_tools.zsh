#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Installing Kubernetes tools on macOS...$reset_color

brew update

brew install kubernetes-cli
brew install helm
brew install stern
brew tap sozercan/kubectl-ai https://github.com/sozercan/kubectl-ai
brew install kubectl-ai
brew install azure-cli
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
brew install --cask openlens
brew install --cask freelens
brew install kubeshark

echo $fg[cyan]Finished installing Kubernetes tools on macOS!$reset_color
