#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Replay Forensics aliases...$reset_color

alias rfi-github-cd="cd ~/github-sandbox/ReplayForensics && pwd && rfi-add-ssh-key && rfi-git-config"
alias rfi-frontend-app-cd="cd ~/github-sandbox/ReplayForensics/frontend-app && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-frontend-spikes-cd="cd ~/github-sandbox/ReplayForensics/frontend-spikes && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-add-ssh-key="ssh-add -D && ssh-add ~/.ssh/id_ed25519_rfi && ssh-add -l"
alias rfi-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris@replayforensics.com\""

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]rfi-github-cd$reset_color
echo $fg[yellow]rfi-frontend-app-cd$reset_color
echo $fg[yellow]rfi-frontend-spikes-cd$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]rfi-add-ssh-key$reset_color
echo $fg[yellow]rfi-git-config$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
