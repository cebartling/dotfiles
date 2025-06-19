#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Life Time, Inc. aliases...$reset_color

alias lt-github-home-cd="cd ~/github-sandbox/lifetime && pwd && lt-set-git"
alias lt-splunkspike-cd="cd ~/github-sandbox/lifetime/splunkspike && pwd && lt-set-git"
alias lt-ops-confluent-kafka-cd="cd ~/github-sandbox/lifetime/ops-confluent-kafka && pwd && lt-set-git"

alias lt-add-ssh-key="ssh-add -D && ssh-add ~/.ssh/id_ed25519_life_time && ssh-add -l"
alias lt-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"cbartling@lt.life\""
alias lt-set-git="lt-add-ssh-key && lt-git-config"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]lt-github-home-cd$reset_color
echo $fg[yellow]lt-splunkspike-cd$reset_color
echo $fg[yellow]lt-ops-confluent-kafka-cd$reset_color
echo ""
echo $fg[yellow]lt-add-ssh-key$reset_color
echo $fg[yellow]lt-git-config$reset_color
echo $fg[yellow]lt-set-git$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
