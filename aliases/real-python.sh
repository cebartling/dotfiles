#!/bin/zsh

autoload colors; colors

# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"

echo $fg[cyan]Configuring Real Python solutions aliases...$reset_color


alias real-python-solutions-cd="cd ~/github-sandbox/cebartling/real-python-solutions"
alias python-basics-cd="cd ~/github-sandbox/cebartling/real-python-solutions/python-basics && poetry shell"


echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]real-python-solutions-cd$reset_color
echo $fg[yellow]python-basics-cd$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
