{ pkgs, ... }:

{
  packages = with pkgs; [ just wget ];
}
