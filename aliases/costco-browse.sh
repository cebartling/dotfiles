#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Costco Digital Browse Modernization aliases...$reset_color

alias costco-browse-cd="cd ~/github-sandbox/costco/browse.costco.web && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-forge-cd="cd ~/github-sandbox/costco/forge.digital.components && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-search-cd="cd ~/github-sandbox/costco/search.costco.web && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-add-ssh-key="ssh-add ~/.ssh/costco-rsa-key && ssh-add -l"
alias costco-git-config="git config user.name && git config user.email"

alias costco-start-redis="docker remove costco-browse-redis-stack && docker run -d --name costco-browse-redis-stack -p 6379:6379  redis/redis-stack-server:latest"
alias costco-start-redis-insight="docker remove costco-browse-redis-insight && docker run -d --name costco-browse-redis-insight -p 5540:5540 redis/redisinsight:latest"
alias costco-stop-redis="docker container stop costco-browse-redis-stack"
alias costco-stop-redis-insight="docker container stop costco-browse-redis-insight"
alias costco-package-forge="npm run build && npm run pack"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]costco-browse-cd$reset_color
echo $fg[yellow]costco-forge-cd$reset_color
echo $fg[yellow]costco-search-cd$reset_color
echo $fg[yellow]costco-add-ssh-key$reset_color
echo $fg[yellow]costco-git-config$reset_color
echo ""
echo $fg[yellow]costco-start-redis$reset_color
echo $fg[yellow]costco-stop-redis$reset_color
echo $fg[yellow]costco-start-redis-insight$reset_color
echo $fg[yellow]costco-stop-redis-insight$reset_color
echo ""
echo $fg[yellow]costco-package-forge$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
