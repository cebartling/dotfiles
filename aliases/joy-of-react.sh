#!/bin/zsh

autoload colors; colors

# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"

echo $fg[cyan]Configuring Joy of React exercises aliases...$reset_color


alias joy-of-react-project-wordle-cd="cd ~/github-sandbox/cebartling/joy-of-react-project-wordle && nvm use && pwd"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]joy-of-react-project-wordle-cd$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
