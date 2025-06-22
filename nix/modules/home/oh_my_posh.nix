{ files, ... }: {
  programs.oh-my-posh = {
    enable = true;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext
      (builtins.readFile "${files}/custom.omp.json"));
  };
}

