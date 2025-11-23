#!/bin/zsh

source ~/.dotfiles/runtimes/sdkman.sh

sdk use java 21.0.8-amzn

autoload colors
colors

echo ""
echo $fg[cyan]Configuring aliases for Spring Boot spikes...$reset_color

alias spring-boot-spikes-git-clone="cd ~/github-sandbox/cebartling && git clone git@github.com:cebartling/spring-boot-spikes.git"
alias spring-boot-spikes-cd="cd ~/github-sandbox/cebartling/spring-boot-spikes && sdk use java 21.0.8-amzn"
alias spring-boot-spike-cqrs-spike-cd="cd ~/github-sandbox/cebartling/spring-boot-spikes/cqrs-spike && sdk use"
alias spring-boot-spike-resiliency-spike-cd="cd ~/github-sandbox/cebartling/spring-boot-spikes/resiliency-spike && sdk use java 21.0.8-amzn"


echo ""
echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]spring-boot-spikes-git-clone$reset_color
echo ""
echo $fg[yellow]spring-boot-spikes-cd$reset_color
echo ""
echo $fg[yellow]spring-boot-spike-cqrs-spike-cd$reset_color
echo $fg[yellow]spring-boot-spike-resiliency-spike-cd$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
