#!/bin/zsh

echo "Installing essentials tools on Ubuntu..."

sudo apt install -y openssl
sudo apt install -y git
sudo apt install -y curl
sudo apt install -y bat
sudo apt install -y exa
sudo apt install -y fd-find
sudo apt install -y ripgrep
sudo apt install -y fonts-hack-ttf
sudo snap install httpie
sudo snap install procs

echo "Finished installing essentials tools on Ubuntu!"
