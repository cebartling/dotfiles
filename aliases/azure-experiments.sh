# Azure experiments aliases (auto-loaded by functions/project-aliases.sh).
# Run `azure-experiments-help` to print available aliases.

alias azure-experiments-cd="cd ~/github-sandbox/cebartling/azure-experiments && nvm use && pwd"

azure-experiments-help() {
  cat <<'EOF'
Azure experiments aliases
-------------------------
azure-experiments-cd
EOF
}
