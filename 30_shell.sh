#!/bin/sh

echo "Changing default shell to 'zsh'"
chsh -s /bin/zsh

echo "Installing Oh My Zsh"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#setup asdf completion
#Setup plugins: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins
#Setup aliases (cat -> bat), etc

echo "Setup Tmux"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "Installing Powerlevel 10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
