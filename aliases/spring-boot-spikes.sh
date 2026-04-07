# Spring Boot spikes aliases (auto-loaded by functions/project-aliases.sh).
# Run `spring-boot-spikes-help` to print available aliases.
#
# Note: cd aliases call `sdk use java 21.0.8-amzn` which triggers the
# lazy-loaded sdk function on first use, so we don't need to source
# sdkman at the top of this file.

alias spring-boot-spikes-git-clone="cd ~/github-sandbox/cebartling && git clone git@github.com:cebartling/spring-boot-spikes.git"
alias spring-boot-spikes-cd="cd ~/github-sandbox/cebartling/spring-boot-spikes && sdk use java 21.0.8-amzn"
alias spring-boot-spikes-cqrs-spike-cd="cd ~/github-sandbox/cebartling/spring-boot-spikes/cqrs-spike && sdk env"
alias spring-boot-spikes-resiliency-spike-cd="cd ~/github-sandbox/cebartling/spring-boot-spikes/resiliency-spike && sdk env"
alias spring-boot-spikes-saga-pattern-spike-cd="cd ~/github-sandbox/cebartling/spring-boot-spikes/saga-pattern-spike && sdk env"
alias spring-boot-spikes-cdc-debezium-cd="cd ~/github-sandbox/cebartling/spring-boot-spikes/cdc-debezium && sdk env"

spring-boot-spikes-help() {
  cat <<'EOF'
Spring Boot spikes aliases
--------------------------
spring-boot-spikes-git-clone
spring-boot-spikes-cd
spring-boot-spikes-cqrs-spike-cd
spring-boot-spikes-resiliency-spike-cd
spring-boot-spikes-saga-pattern-spike-cd
spring-boot-spikes-cdc-debezium-cd
EOF
}
