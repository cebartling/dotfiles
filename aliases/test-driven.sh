# Test-driven examples aliases (auto-loaded by functions/project-aliases.sh).
# Run `test-driven-help` to print available aliases.

alias test-driven-cd="cd ~/github-sandbox/cebartling/test-driven"
alias test-driven-spring-boot-webflux-tdd-demo-cd="cd ~/github-sandbox/cebartling/test-driven/spring-boot/webflux-tdd-demo && pwd && java11"
alias test-driven-testcontainers-java-demo-cd="cd ~/github-sandbox/cebartling/test-driven/testcontainers/java-demo && pwd && java11"
alias test-driven-testcontainers-cassandra-demo-cd="cd ~/github-sandbox/cebartling/test-driven/testcontainers/cassandra-webflux-demo && pwd && java11"
alias test-driven-dotnet-tdd-example-cd="cd ~/github-sandbox/cebartling/test-driven/dotnet/tdd-example && pwd"

alias test-driven-angular-example1-cd="cd ~/github-sandbox/cebartling/test-driven/angular/example1 && pwd && nvm use"
alias test-driven-svelte-example1-cd="cd ~/github-sandbox/cebartling/test-driven/svelte/example1 && pwd && nvm use"
alias test-driven-react-example1-cd="cd ~/github-sandbox/cebartling/test-driven/react/example1 && pwd && nvm use"

alias test-driven-storybook-angular-cd="cd ~/github-sandbox/cebartling/test-driven/storybook/angular/storybook-example && pwd && nvm use"
alias test-driven-storybook-svelte-cd="cd ~/github-sandbox/cebartling/test-driven/storybook/svelte/storybook-example && pwd && nvm use"

test-driven-help() {
  cat <<'EOF'
Test-driven examples aliases
----------------------------
test-driven-cd
test-driven-spring-boot-webflux-tdd-demo-cd
test-driven-testcontainers-java-demo-cd
test-driven-testcontainers-cassandra-demo-cd
test-driven-angular-example1-cd
test-driven-svelte-example1-cd
test-driven-react-example1-cd
test-driven-storybook-angular-cd
test-driven-storybook-svelte-cd
test-driven-dotnet-tdd-example-cd
EOF
}
