#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Installing Kubernetes tools on macOS...$reset_color

brew install kubernetes-cli
brew tap sozercan/kubectl-ai https://github.com/sozercan/kubectl-ai
brew install kubectl-ai
brew install azure-cli
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

echo $fg[cyan]Finished installing Kubernetes tools on macOS!$reset_color
