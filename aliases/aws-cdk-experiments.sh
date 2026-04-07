# AWS CDK experiments aliases (auto-loaded by functions/project-aliases.sh).
# Run `aws-cdk-experiments-help` to print available aliases.

alias aws-cdk-experiments-cd="cd ~/github-sandbox/cebartling/aws-cdk-experiments && pwd"
alias install-aws-cdk="npm install -g aws-cdk"

aws-cdk-experiments-help() {
  cat <<'EOF'
AWS CDK experiments aliases
---------------------------
aws-cdk-experiments-cd
install-aws-cdk
EOF
}
