# Tailwind CSS Experiments aliases (auto-loaded by functions/project-aliases.sh).
# Run `tailwind-css-experiments-help` to print available aliases.

alias tailwind-css-experiments-cd="cd ~/github-sandbox/cebartling/tailwind-css-experiments"
alias tailwind-basic-experiments-cd="cd ~/github-sandbox/cebartling/tailwind-css-experiments/basic-experiments && nvm use"
alias tailwind-api-server-cd="cd ~/github-sandbox/cebartling/tailwind-css-experiments/api-server && nvm use"

tailwind-css-experiments-help() {
  cat <<'EOF'
Tailwind CSS Experiments aliases
--------------------------------
tailwind-css-experiments-cd
tailwind-basic-experiments-cd
tailwind-api-server-cd
EOF
}
