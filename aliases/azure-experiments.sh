#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Azure experiments aliases...$reset_color

alias azure-experiments-cd="cd ~/github-sandbox/cebartling/azure-experiments && nvm use && pwd"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]azure-experiments-cd$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
