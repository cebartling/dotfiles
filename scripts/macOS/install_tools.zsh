#!/bin/zsh

autoload colors
colors

echo $fg[cyan]Installing essential tools on macOS...$reset_color

brew update

brew tap hashicorp/tap

brew install 1password-cli
brew install awslogs
brew install bat
brew install beads
brew install caddy
brew install cheat
brew install cliclick
brew install copilot-cli
brew install curl
brew install derailed/k9s/k9s
brew install devutils
brew install direnv
brew install dnsmasq
brew install doctl
brew install dog
brew install duckdb
brew install dust
brew install eza
brew install fastfetch
brew install fd
brew install figlet
brew install fx
brew install fzf
brew install gh
brew install git
brew install git-delta
brew install hashicorp/tap/vault
brew install heroku/brew/heroku
brew install httpie
brew install hyperfine
brew install jq
brew install just
brew install lolcat
brew install mongodb-atlas
brew install openssl
brew install oven-sh/bun/bun
brew install pandoc
brew install playwright-cli
brew install podman
brew install procs
brew install ripgrep
brew install semgrep
brew install specify
brew install starship
brew install tailscale
brew install tmux
brew install uv
brew install vale
brew install watchexec
brew install whisperkit-cli
brew install xcodegen
brew install xh

brew tap entireio/tap && brew install entireio/tap/entire


brew install --cask blender
brew install --cask chatgpt
brew install --cask claude
brew install --cask claude-code
brew tap manaflow-ai/cmux && brew install --cask cmux
brew install --cask flashspace
brew install --cask gitkraken
brew install --cask keepingyouawake
brew install --cask lookaway
brew install --cask maccy
brew install --cask mongodb-compass
brew install --cask moom
brew install --cask obsidian
brew install --cask postman
brew install --cask productdevbook/tap/portkiller
brew install --cask raycast
brew install --cask sloth
brew install --cask tailscale-app
brew install --cask warp
brew install --cask wave
brew install --cask witch
brew install --cask zed

echo $fg[cyan]Finished installing essential tools on macOS!$reset_color
