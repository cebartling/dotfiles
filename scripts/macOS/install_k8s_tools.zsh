#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Installing Kubernetes tools on macOS...$reset_color

brew update

brew tap sozercan/kubectl-ai https://github.com/sozercan/kubectl-ai
brew tap weaveworks/tap

brew install azure-cli
brew install helm
brew install kubectl-ai
brew install kubeshark
brew install kubernetes-cli
brew install stern
brew install weaveworks/tap/eksctl

brew install --cask freelens
brew install --cask openlens

echo $fg[cyan]Finished installing Kubernetes tools on macOS!$reset_color
