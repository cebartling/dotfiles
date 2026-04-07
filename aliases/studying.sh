# Studying aliases (auto-loaded by functions/project-aliases.sh).
# Run `studying-help` to print available aliases.

alias study-guides-and-cheatsheets-cd="cd ~/github-sandbox/cebartling/study-guides-and-cheatsheets"

alias study-books-cd="cd ~/github-sandbox/cebartling/study-books"
alias study-books-build="cd ~/github-sandbox/cebartling/study-books && mdbook build"
alias study-books-serve="cd ~/github-sandbox/cebartling/study-books && mdbook serve"
alias study-books-open-browser="open http://localhost:3000"

alias aws-certified-solution-architect-associate-2020-cd="cd ~/github-sandbox/cebartling/aws-certified-solution-architect-associate-2020"

studying-help() {
  cat <<'EOF'
Studying aliases
----------------
study-guides-and-cheatsheets-cd
study-books-cd
study-books-build
study-books-serve
study-books-open-browser
aws-certified-solution-architect-associate-2020-cd
EOF
}
