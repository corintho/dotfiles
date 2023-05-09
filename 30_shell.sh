#!/bin/sh

echo "Changing default shell to 'zsh'"
chsh -s /bin/zsh

echo "Installing Oh My Zsh"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#setup asdf completion
#Setup plugins: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins
#Setup aliases (cat -> bat), etc

echo "Installing Oh My Tmux"
cd ~
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
#This is handled in the rc symlink setup
#cp .tmux/.tmux.conf.local .

echo "Installing Powerlevel 10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
