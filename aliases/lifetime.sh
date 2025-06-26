#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Life Time, Inc. aliases...$reset_color

alias lt-github-home-cd="cd ~/github-sandbox/lifetime && pwd && lt-git-setup"
alias lt-splunkspike-cd="cd ~/github-sandbox/lifetime/splunkspike && pwd && lt-git-setup"
alias lt-ops-confluent-kafka-cd="cd ~/github-sandbox/lifetime/ops-confluent-kafka && pwd && lt-git-setup"
alias lt-credit-card-account-consumer-cd="cd ~/github-sandbox/lifetime/credit-card-account-consumer && pwd && lt-git-setup"


alias lt-add-ssh-key="ssh-add -D && ssh-add -t 8h ~/.ssh/id_ed25519_life_time && ssh-add -l"
alias lt-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"cbartling@lt.life\""
alias lt-git-setup="lt-add-ssh-key && lt-git-config"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]lt-github-home-cd$reset_color
echo $fg[yellow]lt-splunkspike-cd$reset_color
echo $fg[yellow]lt-ops-confluent-kafka-cd$reset_color
echo $fg[yellow]lt-credit-card-account-consumer-cd$reset_color
echo ""
echo $fg[yellow]lt-add-ssh-key$reset_color
echo $fg[yellow]lt-git-config$reset_color
echo $fg[yellow]lt-git-setup$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
