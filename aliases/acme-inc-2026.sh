#!/bin/zsh

autoload colors
colors

echo ""
echo $fg[cyan]Configuring ACME, Inc. 2026 aliases...$reset_color

alias acme-inc-2026-cd="cd ~/github-sandbox/cebartling/acme-inc-2026 && pwd && personal-add-ssh-key && personal-git-config"

echo ""
echo $fg[cyan]Available aliases$reset_color
echo $fg[cyan]---------------------------------------------------$reset_color
echo $fg[yellow]acme-inc-2026-cd$reset_color
echo ""
echo $fg[cyan]---------------------------------------------------$reset_color
