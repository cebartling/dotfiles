# D3.js experiments aliases (auto-loaded by functions/project-aliases.sh).
# Run `d3-experiments-help` to print available aliases.

alias d3-experiments-cd="cd ~/github-sandbox/cebartling/d3-experiments && nvm use && pwd && personal-add-ssh-key && personal-git-config"
alias d3-experiments-react-cd="cd ~/github-sandbox/cebartling/d3-experiments/d3-react && nvm use && pwd && personal-add-ssh-key && personal-git-config"
alias d3-experiments-api-server-cd="cd ~/github-sandbox/cebartling/d3-experiments/api-server && nvm use && pwd && personal-add-ssh-key && personal-git-config"

d3-experiments-help() {
  cat <<'EOF'
D3.js experiments aliases
-------------------------
d3-experiments-cd
d3-experiments-react-cd
d3-experiments-api-server-cd
EOF
}
