#!/bin/zsh

autoload colors
colors

echo ""
echo $fg[cyan]Configuring Life Time, Inc. aliases...$reset_color

alias lt-github-home-cd="cd ~/github-sandbox/lifetime && pwd && lt-git-setup"
alias lt-splunkspike-cd="cd ~/github-sandbox/lifetime/splunkspike && pwd && lt-git-setup"
alias lt-ops-confluent-kafka-cd="cd ~/github-sandbox/lifetime/ops-confluent-kafka && pwd && lt-git-setup"
alias lt-credit-card-account-consumer-cd="cd ~/github-sandbox/lifetime/credit-card-account-consumer && pwd && lt-git-setup"
alias lt-register-credit-card-account-consumer-cd="cd ~/github-sandbox/lifetime/register-credit-card-account-consumer && pwd && lt-git-setup"
alias lt-suite-creditcardaccount-debezium-connector-cd="cd ~/github-sandbox/lifetime/ltsuite-creditcardaccount-debezium-connector && pwd && lt-git-setup"
alias lt-chase-oauth-spike-cd="cd ~/github-sandbox/lifetime/chase-oauth-spike && pwd && lt-git-setup"

alias lt-docker-compose-down="docker compose --profile infrastructure down -v --remove-orphans"

alias lt-add-ssh-key="ssh-add -D && ssh-add -t 24h ~/.ssh/id_ed25519 && ssh-add -l"
alias lt-add-personal-ssh-key="ssh-add -D && ssh-add -t 24h ~/.ssh/id_ed25519_personal && ssh-add -l"
alias lt-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"cbartling@lt.life\""
alias lt-git-setup="lt-add-ssh-key && lt-git-config"

echo ""
echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]lt-github-home-cd$reset_color
echo $fg[yellow]lt-credit-card-account-consumer-cd$reset_color
echo $fg[yellow]lt-register-credit-card-account-consumer-cd$reset_color
echo ""
echo $fg[yellow]lt-add-ssh-key$reset_color
echo $fg[yellow]lt-add-personal-ssh-key$reset_color
echo $fg[yellow]lt-git-config$reset_color
echo $fg[yellow]lt-git-setup$reset_color
echo $fg[yellow]lt-docker-compose-down$reset_color
echo ""
echo $fg[yellow]lt-splunkspike-cd$reset_color
echo $fg[yellow]lt-ops-confluent-kafka-cd$reset_color
echo $fg[yellow]lt-suite-creditcardaccount-debezium-connector-cd$reset_color
echo $fg[yellow]lt-chase-oauth-spike-cd$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
