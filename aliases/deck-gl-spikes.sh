#!/bin/zsh

autoload colors
colors

echo ""
echo $fg[cyan]Configuring aliases for deck.gl spikes...$reset_color

alias deck-gl-spikes-git-clone="cd ~/github-sandbox/cebartling && git clone git@github.com:cebartling/deck-gl-spikes.git"
alias deck-gl-spikes-cd="cd ~/github-sandbox/cebartling/deck-gl-spikes && nvm use && pwd"
alias deck-gl-react-spike-cd="cd ~/github-sandbox/cebartling/deck-gl-spikes/react-deck-gl-spike && nvm use && pwd"

echo ""
echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]deck-gl-spikes-git-clone$reset_color
echo ""
echo $fg[yellow]deck-gl-spikes-cd$reset_color
echo ""
echo $fg[yellow]deck-gl-react-spike-cd$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
