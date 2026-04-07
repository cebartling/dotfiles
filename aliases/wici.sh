# Schoolhouse Educational Services / WICI aliases
# (auto-loaded by functions/project-aliases.sh).
# Run `wici-help` to print available aliases.

alias wici-home-cd="cd ~/github-sandbox/schoolhouse-educational-services && pwd && wici-git-setup"
alias wici-api-cd="cd ~/github-sandbox/schoolhouse-educational-services/wici-api && pwd && wici-git-setup && nvm use"
alias wici-client-cd="cd ~/github-sandbox/schoolhouse-educational-services/wici-client && pwd && wici-git-setup && nvm use"
alias wici-tools-cd="cd ~/github-sandbox/schoolhouse-educational-services/wici-tools && pwd && wici-git-setup"
alias wici-acceptance-tests-cd="cd ~/github-sandbox/schoolhouse-educational-services/wici-acceptance-tests && pwd && wici-git-setup && nvm use"
alias wici-web-client-v2-cd="cd ~/github-sandbox/schoolhouse-educational-services/web-client-v2 && pwd && wici-git-setup && nvm use"

alias wici-services-up="docker compose up -d"
alias wici-services-down="docker compose down -v --remove-orphans"

alias wici-add-ssh-key="ssh-add -D && ssh-add -t 24h ~/.ssh/id_ed25519 && ssh-add -l"
alias wici-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris.bartling@gmail.com\""
alias wici-git-setup="wici-add-ssh-key && wici-git-config"

wici-help() {
  cat <<'EOF'
Schoolhouse Educational Services / WICI aliases
-----------------------------------------------
wici-home-cd

wici-api-cd
wici-client-cd
wici-tools-cd
wici-acceptance-tests-cd
wici-web-client-v2-cd

wici-add-ssh-key
wici-git-config
wici-git-setup

wici-services-up
wici-services-down
EOF
}
