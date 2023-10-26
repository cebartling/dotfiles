#!/bin/zsh

autoload colors; colors

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

echo $fg[cyan]Configuring AWS CDK experiments aliases...$reset_color


alias aws-cdk-experiments-cd="cd ~/github-sandbox/cebartling/aws-cdk-experiments && pwd"
alias install-aws-cdk="npm install -g aws-cdk"


echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]aws-cdk-experiments-cd$reset_color
echo $fg[yellow]install-aws-cdk$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
