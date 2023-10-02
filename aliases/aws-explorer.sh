#!/bin/zsh

autoload colors; colors


echo $fg[cyan]Configuring AWS Explorer aliases...$reset_color

alias aws-explorer-cd="cd ~/github-sandbox/cebartling/aws-explorer && pwd && sdk env"


echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]aws-explorer-cd$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
