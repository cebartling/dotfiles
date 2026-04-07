# Remix experiments aliases (auto-loaded by functions/project-aliases.sh).
# Run `remix-experiments-help` to print available aliases.

alias remix-experiments-cd="cd ~/github-sandbox/cebartling/remix-experiments && pwd"
alias remix-experiments-example1-cd="cd ~/github-sandbox/cebartling/remix-experiments/example1 && pwd && nvm use"
alias remix-experiments-auth0-integration-cd="cd ~/github-sandbox/cebartling/remix-experiments/auth0-integration && pwd && nvm use"
alias remix-experiments-stripe-payment-element-cd="cd ~/github-sandbox/cebartling/remix-experiments/stripe-payment-element && pwd && nvm use"

remix-experiments-help() {
  cat <<'EOF'
Remix experiments aliases
-------------------------
remix-experiments-cd
remix-experiments-example1-cd
remix-experiments-auth0-integration-cd
remix-experiments-stripe-payment-element-cd
EOF
}
