#!/bin/zsh

autoload colors; colors

echo $fg[cyan]Configuring Kafka experiments aliases...$reset_color


alias git-set-ssh-key="ssh-add -D && ssh-add -t 24h ~/.ssh/id_ed25519 && ssh-add -l"
alias git-set-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris.bartling@gmail.com\""

alias kafka-experiments-cd="cd ~/github-sandbox/cebartling/kafka-experiments && pwd && git-set-ssh-key && git-set-config"
alias kafka-experiments-example1-cd="cd ~/github-sandbox/cebartling/kafka-experiments/example1 && pwd && git-set-ssh-key && git-set-config"
alias kafka-experiments-example2-cd="cd ~/github-sandbox/cebartling/kafka-experiments/example2 && pwd && git-set-ssh-key && git-set-config"
alias kafka-experiments-example3-cd="cd ~/github-sandbox/cebartling/kafka-experiments/example3 && pwd && git-set-ssh-key && git-set-config"
alias kafka-experiments-example4-cd="cd ~/github-sandbox/cebartling/kafka-experiments/example4 && pwd && git-set-ssh-key && git-set-config"


echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]kafka-experiments-cd$reset_color
echo $fg[yellow]kafka-experiments-example1-cd$reset_color
echo $fg[yellow]kafka-experiments-example2-cd$reset_color
echo $fg[yellow]kafka-experiments-example3-cd$reset_color
echo $fg[yellow]kafka-experiments-example4-cd$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
