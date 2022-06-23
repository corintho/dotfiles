#!/bin/sh

# install yarn
npm install --global yarn
# install cocoapods
sudo gem install cocoapods -v 1.11.3
# install and setup rust (unattended)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
