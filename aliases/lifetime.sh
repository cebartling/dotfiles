#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Life Time, Inc. aliases...$reset_color

alias lt-home-cd="cd ~/github-sandbox/lifetime && pwd"
alias lt-add-ssh-key="ssh-add -D && ssh-add ~/.ssh/id_ed25519 && ssh-add -l"
alias lt-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"cbartling@lt.life\""

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]lt-home-cd$reset_color
echo ""
echo $fg[yellow]lt-add-ssh-key$reset_color
echo $fg[yellow]lt-git-config$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
