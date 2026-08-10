{ ... }: {
  programs.oh-my-posh = {
    enable = true;
    settings = builtins.fromJSON (builtins.readFile ./oh-my-posh/simple.omp.json);
  };
}
