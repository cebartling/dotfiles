#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Replay Forensics aliases...$reset_color

alias rfi-github-cd="cd ~/github-sandbox/ReplayForensics && pwd && rfi-add-ssh-key && rfi-git-config"
alias rfi-gen1-demo-cd="cd ~/github-sandbox/ReplayForensics/gen1_demo && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-replay-platform-cd="cd ~/github-sandbox/ReplayForensics/Replay_Platform && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-frontend-app-cd="cd ~/github-sandbox/ReplayForensics/frontend-app && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-frontend-react-app-cd="cd ~/github-sandbox/ReplayForensics/frontend-app/react-spa && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-frontend-fastify-server-cd="cd ~/github-sandbox/ReplayForensics/frontend-app/fastify-server && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-frontend-spikes-cd="cd ~/github-sandbox/ReplayForensics/frontend-spikes && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"

alias rfi-add-ssh-key="ssh-add -D && ssh-add ~/.ssh/id_ed25519_rfi && ssh-add -l"
alias rfi-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris@replayforensics.com\""
alias rfi-start-fastify-server="export DATA_SERVER_BASE_URL=http://127.0.0.1:8700 && npm run dev"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]rfi-github-cd$reset_color
echo $fg[yellow]rfi-gen1-demo-cd$reset_color
echo $fg[yellow]rfi-replay-platform-cd$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]rfi-frontend-app-cd$reset_color
echo $fg[yellow]rfi-frontend-react-app-cd$reset_color
echo $fg[yellow]rfi-frontend-fastify-server-cd$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]rfi-frontend-spikes-cd$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]rfi-add-ssh-key$reset_color
echo $fg[yellow]rfi-git-config$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]rfi-start-fastify-server$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
