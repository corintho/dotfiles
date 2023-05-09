#!/bin/zsh

asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install nodejs lts
asdf global nodejs lts

asdf plugin-add java https://github.com/halcyon/asdf-java.git
asdf install java zulu-11.56.19
asdf global java zulu-11.56.19

asdf plugin-add dotnet-core https://github.com/emersonsoares/asdf-dotnet-core.git
asdf install dotnet-core latest
asdf global dotnet-core latest
