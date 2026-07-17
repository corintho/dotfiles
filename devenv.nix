{ pkgs, ... }:

{
  packages = with pkgs; [
    just
    wget
    nil
    (python3.withPackages (py-pkgs: with py-pkgs; [ huggingface-hub ]))
  ];
}
