#!/bin/zsh

autoload colors; colors

echo $fg[cyan]Configuring Costco OMS Modernization engagement aliases...$reset_color

alias costco-oms-ui-cd="cd ~/github-sandbox/costco/oms-ui && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-oms-domain-modeling-cd="cd ~/github-sandbox/costco/oms-domain-modeling && pwd && costco-add-ssh-key && costco-git-config"
alias costco-add-ssh-key="ssh-add ~/.ssh/costco-rsa-key && ssh-add -l"
alias costco-git-config="git config user.name && git config user.email"


echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]costco-oms-ui-cd$reset_color
echo $fg[yellow]costco-oms-domain-modeling-cd$reset_color
echo $fg[yellow]costco-add-ssh-key$reset_color
echo $fg[yellow]costco-git-config$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
