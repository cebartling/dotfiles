# pneuma aliases (auto-loaded by functions/project-aliases.sh).
# Run `pneuma-help` to print available aliases.

alias pneuma-monorepo-cd="cd ~/github-sandbox/cebartling/pneuma && sdk use java 21.0.3-tem && pwd && git-config"
alias pneuma-app-cd="cd ~/github-sandbox/cebartling/pneuma/apps/pneuma && sdk use java 21.0.3-tem && pwd && git-config"

pneuma-help() {
  cat <<'EOF'
pneuma aliases
--------------
pneuma-monorepo-cd
pneuma-app-cd
EOF
}
