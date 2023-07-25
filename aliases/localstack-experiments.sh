#!/bin/zsh

autoload colors; colors

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

echo $fg[cyan]Configuring LocalStack experiments aliases...$reset_color


alias localstack-experiments-cd="cd ~/github-sandbox/cebartling/localstack-experiments && pwd"



echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]localstack-experiments-cd$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
