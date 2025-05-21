#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Replay Forensics aliases...$reset_color

alias rfi-github-cd="cd ~/github-sandbox/ReplayForensics && pwd && rfi-add-ssh-key && rfi-git-config"
alias rfi-gen1-demo-cd="cd ~/github-sandbox/ReplayForensics/gen1_demo && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-replay-platform-cd="cd ~/github-sandbox/ReplayForensics/Replay_Platform && pwd && rfi-add-ssh-key && rfi-git-config"
alias rfi-react-app-cd="cd ~/github-sandbox/ReplayForensics/Replay_Platform/frontend/react-spa && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-fastify-server-cd="cd ~/github-sandbox/ReplayForensics/Replay_Platform/frontend/fastify-server && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-frontend-spikes-cd="cd ~/github-sandbox/ReplayForensics/frontend-spikes && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"

alias rfi-add-ssh-key="ssh-add -D && ssh-add ~/.ssh/id_ed25519_rfi && ssh-add -l"
alias rfi-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris@replayforensics.com\""

alias rfi-dc-up-react-dev="docker compose --profile react-dev up"
alias rfi-dc-down-react-dev="docker compose --profile react-dev down"
alias rfi-dc-down-rmi-react-dev="docker compose --profile react-dev down --rmi all"

alias rfi-dc-up-fastify-dev="docker compose --profile fastify-dev up"
alias rfi-dc-down-fastify-dev="docker compose --profile fastify-dev down"
alias rfi-dc-down-rmi-fastify-dev="docker compose --profile fastify-dev down --rmi all"

alias rfi-dc-up-demo-mode="docker compose --profile demo-mode up"
alias rfi-dc-down-demo-mode="docker compose --profile demo-mode down"
alias rfi-dc-down-rmi-demo-mode="docker compose --profile demo-mode down --rmi all"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]rfi-replay-platform-cd$reset_color
echo $fg[yellow]rfi-react-app-cd$reset_color
echo $fg[yellow]rfi-fastify-server-cd$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]rfi-dc-up-react-dev$reset_color
echo $fg[yellow]rfi-dc-down-react-dev$reset_color
echo $fg[yellow]rfi-dc-down-rmi-react-dev$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]rfi-dc-up-fastify-dev$reset_color
echo $fg[yellow]rfi-dc-down-fastify-dev$reset_color
echo $fg[yellow]rfi-dc-down-rmi-fastify-dev$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]rfi-dc-up-demo-mode$reset_color
echo $fg[yellow]rfi-dc-down-demo-mode$reset_color
echo $fg[yellow]rfi-dc-down-rmi-demo-mode$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]rfi-github-cd$reset_color
echo $fg[yellow]rfi-frontend-spikes-cd$reset_color
echo $fg[yellow]rfi-gen1-demo-cd$reset_color
echo $fg[yellow]$reset_color
echo $fg[yellow]rfi-add-ssh-key$reset_color
echo $fg[yellow]rfi-git-config$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
