{ config, lib, files, pkgs, ... }:

{

  home.packages = with pkgs; [
    unstable.neovim
    nixd
    nixfmt-classic
    deadnix
    statix
    nodejs_22
    (lua5_1.withPackages (ps: with ps; [ luarocks ]))
  ];

  xdg.configFile = {
    "nvim" = { source = config.lib.file.mkOutOfStoreSymlink "${files}/nvim"; };
  };
  home.activation.nvim = with config.lib.stylix.colors.withHashtag;
    let
      theme = ''
        --DO NOT EDIT. Auto generated from current stylix theme during deploy
        require('mini.base16').setup({
          use_cterm = true,
          palette = {
            base00 = '${base00}',
            base01 = '${base01}',
            base02 = '${base02}',
            base03 = '${base03}',
            base04 = '${base04}',
            base05 = '${base05}',
            base06 = '${base06}',
            base07 = '${base07}',
            base08 = '${base08}',
            base09 = '${base09}',
            base0A = '${base0A}',
            base0B = '${base0B}',
            base0C = '${base0C}',
            base0D = '${base0D}',
            base0E = '${base09}',
            base0F = '${base0F}'
          }
        })

        -- Set overrides for hl groups
        -- Using the command for this one, so we can just change the existing one, instead of replacing it
        vim.cmd \"highlight NeogitDiffDeleteCursor guifg='${base08}' gui=bold\"
      '';
    in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run echo "${theme}" > "${config.home.homeDirectory}/.config/nvim/colors/stylix.lua"
    '';
}
