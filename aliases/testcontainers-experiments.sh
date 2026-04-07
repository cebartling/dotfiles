# Testcontainers experiments aliases (auto-loaded by functions/project-aliases.sh).
# Run `testcontainers-experiments-help` to print available aliases.

alias testcontainers-experiments-cd="cd ~/github-sandbox/cebartling/testcontainers-experiments"
alias testcontainers-experiments-kotlin-demo-cd="cd ~/github-sandbox/cebartling/testcontainers-experiments/kotlin/demo && pwd && sdk use java 17.0.2-tem && java -version"

testcontainers-experiments-help() {
  cat <<'EOF'
Testcontainers experiments aliases
----------------------------------
testcontainers-experiments-cd
testcontainers-experiments-kotlin-demo-cd
EOF
}
