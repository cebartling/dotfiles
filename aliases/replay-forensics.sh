# Replay Forensics aliases (auto-loaded by functions/project-aliases.sh).
# Run `replay-forensics-help` to print available aliases.

alias rfi-github-cd="cd ~/github-sandbox/ReplayForensics && pwd && rfi-add-ssh-key && rfi-git-config"
alias rfi-gen1-demo-cd="cd ~/github-sandbox/ReplayForensics/gen1_demo && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-replay-platform-cd="cd ~/github-sandbox/ReplayForensics/Replay_Platform && pwd && rfi-add-ssh-key && rfi-git-config"
alias rfi-replay-frontend-cd="cd ~/github-sandbox/ReplayForensics/Replay_Frontend && pwd && rfi-add-ssh-key && rfi-git-config"
alias rfi-react-app-cd="cd ~/github-sandbox/ReplayForensics/Replay_Platform/frontend/react-spa && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-fastify-server-cd="cd ~/github-sandbox/ReplayForensics/Replay_Platform/frontend/fastify-server && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"
alias rfi-data-server-cd="cd ~/github-sandbox/ReplayForensics/Replay_Platform/data-server && pwd && rfi-add-ssh-key && rfi-git-config"
alias rfi-frontend-spikes-cd="cd ~/github-sandbox/ReplayForensics/frontend-spikes && pwd && rfi-add-ssh-key && rfi-git-config && nvm use"

alias rfi-add-ssh-key="ssh-add -D && ssh-add -t 8h ~/.ssh/id_ed25519_rfi && ssh-add -l"
alias rfi-git-config="git config user.name \"Christopher Bartling\" && git config user.email \"chris@replayforensics.com\""
alias rfi-git-setup="rfi-add-ssh-key && rfi-git-config"

alias rfi-dc-up-database-dev="docker compose --profile database-dev up"
alias rfi-dc-down-database-dev="docker compose --profile database-dev down -v --remove-orphans"
alias rfi-dc-down-rmi-database-dev="docker compose --profile database-dev down --rmi all -v --remove-orphans"

alias rfi-dc-up-react-dev="docker compose --profile react-dev up"
alias rfi-dc-down-react-dev="docker compose --profile react-dev down -v --remove-orphans"
alias rfi-dc-down-rmi-react-dev="docker compose --profile react-dev down --rmi all -v --remove-orphans"

alias rfi-dc-up-fastify-dev="docker compose --profile fastify-dev up"
alias rfi-dc-down-fastify-dev="docker compose --profile fastify-dev down -v --remove-orphans"
alias rfi-dc-down-rmi-fastify-dev="docker compose --profile fastify-dev down --rmi all -v --remove-orphans"

alias rfi-dc-up-demo-mode="docker compose --profile demo-mode up"
alias rfi-dc-down-demo-mode="docker compose --profile demo-mode down -v --remove-orphans"
alias rfi-dc-down-rmi-demo-mode="docker compose --profile demo-mode down --rmi all -v --remove-orphans"

alias rfi-dc-run-csv-ingest="docker compose --profile csv-ingest run --rm csv-ingest"
alias rfi-dc-run-data-summarization-init="docker compose --profile data-summarization-init run --rm data-summarization-init"

replay-forensics-help() {
  cat <<'EOF'
Replay Forensics aliases
------------------------
rfi-github-cd
rfi-frontend-spikes-cd
rfi-gen1-demo-cd
rfi-replay-platform-cd
rfi-replay-frontend-cd
rfi-react-app-cd
rfi-fastify-server-cd
rfi-data-server-cd

rfi-add-ssh-key
rfi-git-config
rfi-git-setup

rfi-dc-up-database-dev / -down / -down-rmi
rfi-dc-up-react-dev    / -down / -down-rmi
rfi-dc-up-fastify-dev  / -down / -down-rmi
rfi-dc-up-demo-mode    / -down / -down-rmi

rfi-dc-run-csv-ingest
rfi-dc-run-data-summarization-init
EOF
}
