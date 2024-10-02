#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Costco Digital Browse Modernization aliases...$reset_color

alias costco-browse-cd="cd ~/github-sandbox/costco/browse.costco.web && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-forge-cd="cd ~/github-sandbox/costco/forge.digital.components && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-search-cd="cd ~/github-sandbox/costco/search.costco.web && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-add-ssh-key="ssh-add ~/.ssh/costco-rsa-key && ssh-add -l"
alias costco-git-config="git config user.name && git config user.email"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo ""
echo $fg[yellow]costco-browse-cd$reset_color
echo $fg[yellow]costco-forge-cd$reset_color
echo $fg[yellow]costco-search-cd$reset_color
echo $fg[yellow]costco-add-ssh-key$reset_color
echo $fg[yellow]costco-git-config$reset_color
echo ""
echo $fg[cyan]---------------------------------------------------$reset_color
