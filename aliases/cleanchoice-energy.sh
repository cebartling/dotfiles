#!/bin/zsh

autoload colors; colors

echo $fg[cyan]Configuring CleanChoice Energy CEO aliases...$reset_color


alias cce-ceo-api-cd="cd ~/github-sandbox/cleanchoice/clean-energy-option-API && pwd && nvm use"
alias cce-ceo-cd="cd ~/github-sandbox/cleanchoice/clean-energy-option && pwd && nvm use"
alias cce-ceo-web-ui-cd="cd ~/github-sandbox/cleanchoice/clean-energy-option/web-ui && pwd && nvm use"
alias personal-github-identity="eval \"$(ssh-agent -s)\" && ssh-add ~/.ssh/id_ed25519_personal"


echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]cce-ceo-api-cd$reset_color
echo $fg[yellow]cce-ceo-cd$reset_color
echo $fg[yellow]cce-ceo-web-ui-cd$reset_color
echo $fg[yellow]personal-github-identity$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
