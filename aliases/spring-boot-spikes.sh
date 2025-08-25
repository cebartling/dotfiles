#!/bin/zsh

source ~/.dotfiles/runtimes/sdkman.sh

sdk use java 21.0.8-amzn

autoload colors
colors

echo ""
echo $fg[cyan]Configuring aliases for Spring Boot spikes...$reset_color

alias spring-boot-spike-vault-integration-cd="cd ~/github-sandbox/cebartling/spring-boot-spikes/vault-integration && sdk use java 21.0.8-amzn"


echo ""
echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]spring-boot-spike-vault-integration-cd$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
