#!/bin/zsh
echo "Setting up ~/.rcrc file"
echo "DOTFILES_DIRS=\"$(pwd)/dotfiles\"" > ~/.rcrc

echo "Symlinking the dotfiles"
rcup -v -f
