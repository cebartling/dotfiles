# Coding katas aliases (auto-loaded by functions/project-aliases.sh).
# Run `coding-katas-help` to print available aliases.

alias coding-katas-cd="cd ~/github-sandbox/cebartling/coding-katas"
alias coding-katas-python-cd="cd ~/github-sandbox/cebartling/coding-katas/python/katas && pwd && poetry shell"
alias coding-katas-rust-cd="cd ~/github-sandbox/cebartling/coding-katas/rust/katas && pwd"

coding-katas-help() {
  cat <<'EOF'
Coding katas aliases
--------------------
coding-katas-cd
coding-katas-python-cd
coding-katas-rust-cd
EOF
}
