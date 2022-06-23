#!/bin/sh

echo "Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

echo "Installing brew bundle"
brew tap Homebrew/bundle

echo "Installing dependencies from Brewfile"
brew bundle install
