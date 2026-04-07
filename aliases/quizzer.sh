# Quizzer aliases (auto-loaded by functions/project-aliases.sh).
# Run `quizzer-help` to print available aliases.

alias quizzer-ruby-on-rails-cd="cd ~/github-sandbox/cebartling/certification-exam-quizzer-rails && rvm use"
alias quizzer-react-cd="cd ~/github-sandbox/cebartling/certification-exam-quizzer-react && nvm use"
alias quizzer-build-deploy-react-app="yarn build && firebase deploy"

quizzer-help() {
  cat <<'EOF'
Quizzer aliases
---------------
quizzer-ruby-on-rails-cd
quizzer-react-cd
quizzer-build-deploy-react-app
EOF
}
