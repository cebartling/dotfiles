# Life Time, Inc. aliases (auto-loaded by functions/project-aliases.sh).
# Run `lifetime-help` to print available aliases.

alias lt-credit-card-account-consumer-cd="cd ~/github-sandbox/lifetime/credit-card-account-consumer && pwd && lt-git-setup"
alias lt-register-credit-card-account-consumer-cd="cd ~/github-sandbox/lifetime/register-credit-card-account-consumer && pwd && lt-git-setup"
alias lt-chase-commerce-gateway-api-cd="cd ~/github-sandbox/lifetime/chase-commerce-gateway-api && pwd && lt-git-setup"
alias lt-payment-account-updater-cd="cd ~/github-sandbox/lifetime/payment-account-updater && pwd && lt-git-setup"
alias lt-payments-testing-admin-api-cd="cd ~/github-sandbox/lifetime/payments-testing-admin-api && pwd && lt-git-setup"
alias lt-account-updater-batch-cd="cd ~/github-sandbox/lifetime/account-updater-batch && pwd && lt-git-setup"

alias lt-payment-services-proxy-cd="cd ~/github-sandbox/lifetime/payment-services-proxy && pwd && lt-git-setup"

alias lt-github-home-cd="cd ~/github-sandbox/lifetime && pwd && lt-git-setup"
alias lt-splunkspike-cd="cd ~/github-sandbox/lifetime/splunkspike && pwd && lt-git-setup"
alias lt-ops-confluent-kafka-cd="cd ~/github-sandbox/lifetime/ops-confluent-kafka && pwd && lt-git-setup"
alias lt-suite-creditcardaccount-debezium-connector-cd="cd ~/github-sandbox/lifetime/ltsuite-creditcardaccount-debezium-connector && pwd && lt-git-setup"
alias lt-chase-oauth-spike-cd="cd ~/github-sandbox/lifetime/chase-oauth-spike && pwd && lt-git-setup"
alias lt-spring-batch-spike-cd="cd ~/github-sandbox/lifetime/spring-batch-spike && pwd && lt-git-setup"

alias lt-docker-compose-down="docker compose --profile infrastructure down -v --remove-orphans"

alias lt-add-ssh-key="ssh-add -D && ssh-add -t 24h ~/.ssh/id_ed25519 && ssh-add -l"
alias lt-add-personal-ssh-key="ssh-add -D && ssh-add -t 24h ~/.ssh/id_ed25519_personal && ssh-add -l"
alias lt-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"cbartling@lt.life\""
alias lt-git-setup="lt-add-ssh-key && lt-git-config"
alias lt-git-personal-setup="lt-add-personal-ssh-key && lt-git-config"

lifetime-help() {
  cat <<'EOF'
Life Time, Inc. aliases
-----------------------
lt-github-home-cd

lt-credit-card-account-consumer-cd
lt-register-credit-card-account-consumer-cd
lt-chase-commerce-gateway-api-cd
lt-payment-account-updater-cd
lt-payments-testing-admin-api-cd
lt-account-updater-batch-cd

lt-payment-services-proxy-cd

lt-add-ssh-key
lt-add-personal-ssh-key
lt-git-config
lt-git-setup
lt-git-personal-setup
lt-docker-compose-down

lt-splunkspike-cd
lt-ops-confluent-kafka-cd
lt-suite-creditcardaccount-debezium-connector-cd
lt-chase-oauth-spike-cd
lt-spring-batch-spike-cd
EOF
}
