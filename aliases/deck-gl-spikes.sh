# deck.gl spikes aliases (auto-loaded by functions/project-aliases.sh).
# Run `deck-gl-spikes-help` to print available aliases.

alias deck-gl-spikes-git-clone="cd ~/github-sandbox/cebartling && git clone git@github.com:cebartling/deck-gl-spikes.git"
alias deck-gl-spikes-cd="cd ~/github-sandbox/cebartling/deck-gl-spikes && nvm use && pwd"
alias deck-gl-react-spike-cd="cd ~/github-sandbox/cebartling/deck-gl-spikes/react-deck-gl-spike && nvm use && pwd"

deck-gl-spikes-help() {
  cat <<'EOF'
deck.gl spikes aliases
----------------------
deck-gl-spikes-git-clone
deck-gl-spikes-cd
deck-gl-react-spike-cd
EOF
}
