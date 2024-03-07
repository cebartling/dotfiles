#!/bin/sh

echo "Installing essentials tools on Ubuntu..."

sudo apt install -y openssl
sudo apt install -y git
sudo apt install -y curl
sudo apt install -y bat
sudo apt install -y exa
sudo apt install -y fd-find
sudo apt install -y ripgrep
sudo apt install -y fonts-hack-ttf
sudo apt install -y net-tools
sudo apt install -y tmux

sudo snap install httpie
sudo snap install procs
sudo snap install fx

curl -sS https://starship.rs/install.sh | sh

echo "Finished installing essentials tools on Ubuntu!"
