# Saga pattern demo aliases (auto-loaded by functions/project-aliases.sh).
# Run `saga-pattern-help` to print available aliases.

alias saga-pattern-cd="cd ~/github-sandbox/cebartling/saga-pattern-examples && java11"
alias saga-pattern-basic-example-cd="cd ~/github-sandbox/cebartling/saga-pattern-examples/basic-example && java11"
alias saga-pattern-basic-example-product-cd="cd ~/github-sandbox/cebartling/saga-pattern-examples/basic-example/product && java11"
alias saga-pattern-basic-example-product-run-tests="export JDBC_URL=jdbc:postgresql://localhost:15432/product;export JDBC_USERNAME=product;export JDBC_PASSWORD=product;./gradlew test"

saga-pattern-help() {
  cat <<'EOF'
Saga pattern demo aliases
-------------------------
saga-pattern-cd
saga-pattern-basic-example-cd
saga-pattern-basic-example-product-cd
saga-pattern-basic-example-product-run-tests
EOF
}
