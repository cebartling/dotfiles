#!/bin/zsh

autoload colors; colors

echo $fg[cyan]Configuring Kafka experiments aliases...$reset_color


alias git-set-ssh-key="ssh-add -D && ssh-add -t 24h ~/.ssh/id_ed25519 && ssh-add -l"
alias git-set-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris.bartling@gmail.com\""

alias kafka-experiments-cd="cd ~/github-sandbox/cebartling/kafka-experiments && pwd && git-set-ssh-key && git-set-config"
alias kafka-experiments-experiment-01-cd="cd ~/github-sandbox/cebartling/kafka-experiments/experiment-01 && pwd && git-set-ssh-key && git-set-config"
alias kafka-experiments-experiment-02-cd="cd ~/github-sandbox/cebartling/kafka-experiments/experiment-02 && pwd && git-set-ssh-key && git-set-config"
alias kafka-experiments-experiment-03-cd="cd ~/github-sandbox/cebartling/kafka-experiments/experiment-03 && pwd && git-set-ssh-key && git-set-config"
alias kafka-experiments-experiment-04-cd="cd ~/github-sandbox/cebartling/kafka-experiments/experiment-04 && pwd && git-set-ssh-key && git-set-config"


echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]kafka-experiments-cd$reset_color
echo $fg[yellow]kafka-experiments-experiment-01-cd$reset_color
echo $fg[yellow]kafka-experiments-experiment-02-cd$reset_color
echo $fg[yellow]kafka-experiments-experiment-03-cd$reset_color
echo $fg[yellow]kafka-experiments-experiment-04-cd$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
