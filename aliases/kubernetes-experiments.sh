#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Kubernetes experiments aliases...$reset_color

alias k8s-experiments-cd="cd ~/github-sandbox/cebartling/kubernetes-experiments"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]k8s-experiments-cd$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
