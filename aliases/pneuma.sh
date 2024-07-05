#!/bin/zsh

autoload colors; colors

echo $fg[cyan]Configuring pneuma aliases...$reset_color

alias pneuma-monorepo-cd="cd ~/github-sandbox/cebartling/pneuma && sdk use java 21.0.3-tem && pwd && git-config"
alias pneuma-app-cd="cd ~/github-sandbox/cebartling/pneuma/apps/pneuma && sdk use java 21.0.3-tem && pwd && git-config"

echo ""
echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]pneuma-monorepo-cd$reset_color
echo $fg[yellow]pneuma-app-cd$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
