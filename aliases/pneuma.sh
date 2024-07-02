#!/bin/zsh

autoload colors; colors

echo $fg[cyan]Configuring pneuma aliases...$reset_color

alias pneuma-monorepo-cd="cd ~/github-sandbox/cebartling/pneuma && sdk use java 21.0.3-tem && pwd && costco-git-config"

echo ""
echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]pneuma-monorepo-cd$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
