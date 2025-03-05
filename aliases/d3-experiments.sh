#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring D3.js Experiments aliases...$reset_color

alias personal-add-ssh-key="ssh-add -D && ssh-add ~/.ssh/id_ed25519 && ssh-add -l"
alias personal-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris.bartling@gmail.com\""

alias d3-experiments-cd="cd ~/github-sandbox/cebartling/d3-experiments && nvm use && pwd && personal-add-ssh-key && personal-git-config"
alias d3-experiments-react-cd="cd ~/github-sandbox/cebartling/d3-experiments/d3-react && nvm use && pwd && personal-add-ssh-key && personal-git-config"
alias d3-experiments-api-server-cd="cd ~/github-sandbox/cebartling/d3-experiments/api-server && nvm use && pwd && personal-add-ssh-key && personal-git-config"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]d3-experiments-cd$reset_color
echo $fg[yellow]d3-experiments-react-cd$reset_color
echo $fg[yellow]d3-experiments-api-server-cd$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
