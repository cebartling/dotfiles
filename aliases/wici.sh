#!/bin/zsh

autoload colors
colors

echo ""
echo $fg[cyan]Configuring Schoolhouse Educational Services aliases...$reset_color

alias wici-home-cd="cd ~/github-sandbox/schoolhouse-educational-services && pwd && wici-git-setup"
alias wici-api-cd="cd ~/github-sandbox/schoolhouse-educational-services/wici-api && pwd && wici-git-setup && nvm use"
alias wici-client-cd="cd ~/github-sandbox/schoolhouse-educational-services/wici-client && pwd && wici-git-setup && nvm use"
alias wici-acceptance-tests-cd="cd ~/github-sandbox/schoolhouse-educational-services/wici-acceptance-tests && pwd && wici-git-setup && nvm use"

alias wici-services-up="docker compose up -d"
alias wici-services-down="docker compose down -v --remove-orphans"

alias wici-add-ssh-key="ssh-add -D && ssh-add -t 24h ~/.ssh/id_ed25519 && ssh-add -l"
alias wici-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris.bartling@gmail.com\""
alias wici-git-setup="wici-add-ssh-key && wici-git-config"

echo ""
echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg_bold[yellow]wici-home-cd$reset_color
echo ""
echo $fg_bold[yellow]wici-api-cd$reset_color
echo $fg_bold[yellow]wici-client-cd$reset_color
echo $fg_bold[yellow]wici-acceptance-tests-cd$reset_color
echo ""
echo $fg_bold[yellow]wici-add-ssh-key$reset_color
echo $fg_bold[yellow]wici-git-config$reset_color
echo $fg_bold[yellow]wici-git-setup$reset_color
echo ""
echo $fg_bold[yellow]wici-services-up$reset_color
echo $fg_bold[yellow]wici-services-down$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
