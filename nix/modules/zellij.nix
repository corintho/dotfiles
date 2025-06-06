{ config, lib, ... }: {
  config = {

    programs = {
      zellij = { enable = true; };

      fish = {
        interactiveShellInit =
          "${config.programs.zellij.package}/bin/zellij setup --generate-completion fish | source";
      };
      zsh = {
        initContent = lib.mkAfter ''
          # Add zellij complete and aliases
          source ${./zellij/zellij.zsh}'';
      };
    };
  };
}
