# create the dir for zsh completions
mkdir ~/.zfunc

# install zsh completions for additional tools
bob complete zsh > ~/.zfunc/_bob

# setup bob with the latest stable version of neovim
bob install stable
bob use stable
