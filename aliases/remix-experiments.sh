#!/bin/zsh

autoload colors; colors

echo $fg[cyan]Configuring Remix experiments aliases...$reset_color


alias remix-experiments-cd="cd ~/github-sandbox/cebartling/remix-experiments && pwd"
alias remix-experiments-example1-cd="cd ~/github-sandbox/cebartling/remix-experiments/example1 && pwd && nvm use"
alias remix-experiments-auth0-integration-cd="cd ~/github-sandbox/cebartling/remix-experiments/auth0-integration && pwd && nvm use"
alias remix-experiments-stripe-payment-element-cd="cd ~/github-sandbox/cebartling/remix-experiments/stripe-payment-element && pwd && nvm use"


echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]remix-experiments-cd$reset_color
echo $fg[yellow]remix-experiments-example1-cd$reset_color
echo $fg[yellow]remix-experiments-auth0-integration-cd$reset_color
echo $fg[yellow]remix-experiments-stripe-payment-element-cd$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
