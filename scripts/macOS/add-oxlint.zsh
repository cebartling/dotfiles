#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Adding oxlint to current project...$reset_color

npm install -D oxlint eslint-plugin-oxlint
touch ./oxlintrc.json
cat ~/.dotfiles/templates/oxlint/oxlintrc.json >./oxlintrc.json
