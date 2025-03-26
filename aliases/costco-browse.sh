#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Configuring Costco Digital Browse Modernization aliases...$reset_color

#alias costco-browse-cd="cd ~/github-sandbox/costco/browse.costco.web && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-digital-forge-cd="cd ~/github-sandbox/costco/forge.digital.components && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-public-forge-cd="cd ~/github-sandbox/costco/forge.public.components && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-public-forge-lint-cd="cd ~/github-sandbox/costco/forge.public.lint && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-search-cd="cd ~/github-sandbox/costco/search.costco.web && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-consent-ui-cd="cd ~/github-sandbox/costco/all.costco.web.consent-manager-ui.transcend && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-consent-web-cd="cd ~/github-sandbox/costco/consent.costco.web && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-add-ssh-key="ssh-add -D && ssh-add ~/.ssh/costco-rsa-key && ssh-add -l"
alias costco-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"c_cbartling@costco.com\""

alias costco-gdx-forge-digital-cd="cd ~/github-sandbox/costco/gdx-lib-forge-digital-components && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-gdx-forge-public-cd="cd ~/github-sandbox/costco/gdx-lib-forge-public-components && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-gdx-forge-public-icons-cd="cd ~/github-sandbox/costco/gdx-lib-forge-public-icons && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-gdx-forge-public-tokens-cd="cd ~/github-sandbox/costco/gdx-lib-forge-public-tokens && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-gdx-browse-homepage-cd="cd ~/github-sandbox/costco/gdx-ux-cnsw-browse-homepage && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-gdx-browse-search-cd="cd ~/github-sandbox/costco/gdx-ux-cnsw-browse-search && nvm use && pwd && costco-add-ssh-key && costco-git-config"

alias costco-start-redis="docker remove costco-browse-redis-stack && docker run -d --name costco-browse-redis-stack -p 6379:6379  redis/redis-stack-server:latest"
alias costco-start-redis-insight="docker remove costco-browse-redis-insight && docker run -d --name costco-browse-redis-insight -p 5540:5540 redis/redisinsight:latest"
alias costco-stop-redis="docker container stop costco-browse-redis-stack"
alias costco-stop-redis-insight="docker container stop costco-browse-redis-insight"
alias costco-package-forge="npm run build && npm run pack"

alias costco-export-node-options="export NODE_OPTIONS=--max-old-space-size=8192"
alias costco-export-node-tls-reject-unauthorized="export NODE_TLS_REJECT_UNAUTHORIZED=0"

alias costco-run-nextjs="export NODE_TLS_REJECT_UNAUTHORIZED=0 && npm run dev --max-old-space-size=8192"
alias costco-run-tests="npm test --max-old-space-size=8192"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
#echo $fg[yellow]costco-browse-cd$reset_color
echo $fg[yellow]costco-digital-forge-cd$reset_color
echo $fg[yellow]costco-public-forge-cd$reset_color
echo $fg[yellow]costco-search-cd$reset_color
echo $fg[yellow]costco-consent-ui-cd$reset_color
echo $fg[yellow]costco-consent-web-cd$reset_color
echo $fg[yellow]costco-public-forge-lint-cd$reset_color
echo $fg[yellow]costco-add-ssh-key$reset_color
echo $fg[yellow]costco-git-config$reset_color
echo ""
echo $fg[yellow]costco-gdx-forge-digital-cd$reset_color
echo $fg[yellow]costco-gdx-forge-public-cd$reset_color
echo $fg[yellow]costco-gdx-forge-public-icons-cd$reset_color
echo $fg[yellow]costco-gdx-forge-public-tokens-cd$reset_color
echo $fg[yellow]costco-gdx-browse-homepage-cd$reset_color
echo $fg[yellow]costco-gdx-browse-search-cd$reset_color
echo ""
echo $fg[yellow]costco-start-redis$reset_color
echo $fg[yellow]costco-stop-redis$reset_color
echo $fg[yellow]costco-start-redis-insight$reset_color
echo $fg[yellow]costco-stop-redis-insight$reset_color
echo ""
echo $fg[yellow]costco-package-forge$reset_color
echo $fg[yellow]costco-run-nextjs$reset_color
echo $fg[yellow]costco-run-tests$reset_color
echo ""
echo $fg[yellow]costco-export-node-options$reset_color
echo $fg[yellow]costco-export-node-tls-reject-unauthorized$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
