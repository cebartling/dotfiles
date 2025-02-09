#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Tailwind CSS Experiments aliases...$reset_color

alias tailwind-css-experiments-cd="cd ~/github-sandbox/cebartling/tailwind-css-experiments"
alias tailwind-basic-experiments-cd="cd ~/github-sandbox/cebartling/tailwind-css-experiments/basic-experiments && nvm use"
alias tailwind-api-server-cd="cd ~/github-sandbox/cebartling/tailwind-css-experiments/api-server && nvm use"

alias personal-add-ssh-key="ssh-add -D && ssh-add ~/.ssh/id_ed25519 && ssh-add -l"
alias personal-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris.bartling@gmail.com\""

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]tailwind-css-experiments-cd$reset_color
echo $fg[yellow]tailwind-basic-experiments-cd$reset_color
echo $fg[yellow]tailwind-api-server-cd$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]personal-add-ssh-key$reset_color
echo $fg[yellow]personal-git-config$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
