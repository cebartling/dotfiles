#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Installing development tools on macOS...$reset_color

brew update

brew install kcat   

echo $fg[cyan]Finished installing development tools on macOS!$reset_color
