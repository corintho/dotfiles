#!/bin/sh

echo "Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

echo "Adding brew path"
(echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Installing brew bundle"
brew tap Homebrew/bundle

echo "Installing dependencies from Brewfile"
brew bundle install

echo "Removing neovim installed as dependency for neovide. We handle neovim using bob"
brew uninstall --ignore-dependencies neovim

echo "Installing brew environment variables in .zshenv"
# Find where brew was installed. This currently works because as soon as it is installed it is put in the path
bc=$(which brew)
echo "eval \$($bc shellenv)" >> $HOME/.zshenv
