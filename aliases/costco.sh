#!/bin/zsh

autoload colors; colors

echo $fg[cyan]Configuring Costco OMS Modernization engagement aliases...$reset_color

alias costco-oms-ui-cd="cd ~/github-sandbox/costco/oms-ui && nvm use && pwd && costco-add-ssh-key && costco-git-config"
alias costco-oms-domain-modeling-cd="cd ~/github-sandbox/costco/oms-domain-modeling && pwd && costco-add-ssh-key && costco-git-config"
alias costco-add-ssh-key="ssh-add ~/.ssh/costco-rsa-key && ssh-add -l"
alias costco-git-config="git config user.name && git config user.email"

alias costco-oms-ui-shared-test-typecheck-lint-build="pnpm nx run-many -p shared-ui shared-util -t test typecheck lint build"
alias costco-oms-ui-shared-ui-test="pnpm nx test shared-ui --skip-nx-cache"
alias costco-oms-ui-shared-util-test="pnpm nx test shared-util --skip-nx-cache"

alias costco-oms-ui-host-serve="pnpm nx serve host"
alias costco-oms-ui-host-storybook="pnpm nx run storybook-host:storybook"
alias costco-oms-ui-host-test="pnpm nx test host --skip-nx-cache"
alias costco-oms-ui-host-test-typecheck-lint-build="pnpm nx run-many -p host --skip-nx-cache -t test typecheck lint build"

alias costco-oms-ui-bff-serve="pnpm nx serve bff"
alias costco-oms-ui-bff-test="pnpm nx test bff --skip-nx-cache"
alias costco-oms-ui-bff-test-typecheck-lint-build="pnpm nx run-many -p bff --skip-nx-cache -t test typecheck lint build"

alias costco-oms-ui-all-serve="pnpm nx run-many -t serve -p host,bff"

alias costco-oms-ui-host-e2e-tests="pnpm nx e2e host-e2e"

echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]costco-oms-ui-cd$reset_color
echo $fg[yellow]costco-oms-domain-modeling-cd$reset_color
echo $fg[yellow]costco-add-ssh-key$reset_color
echo $fg[yellow]costco-git-config$reset_color
echo ""
echo $fg[yellow]costco-oms-ui-shared-test-typecheck-lint-build$reset_color
echo $fg[yellow]costco-oms-ui-shared-ui-test$reset_color
echo $fg[yellow]costco-oms-ui-shared-util-test$reset_color
echo ""
echo $fg[yellow]costco-oms-ui-host-serve$reset_color
echo $fg[yellow]costco-oms-ui-host-serve$reset_color
echo $fg[yellow]costco-oms-ui-host-storybook$reset_color
echo $fg[yellow]costco-oms-ui-host-test$reset_color
echo $fg[yellow]costco-oms-ui-host-test-typecheck-lint-build$reset_color
echo ""
echo $fg[yellow]costco-oms-ui-bff-serve$reset_color
echo $fg[yellow]costco-oms-ui-bff-test$reset_color
echo $fg[yellow]costco-oms-ui-bff-test-typecheck-lint-build$reset_color
echo ""
echo $fg[yellow]costco-oms-ui-all-serve$reset_color
echo ""
echo $fg[yellow]costco-oms-ui-host-e2e-tests$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
