{ pkgs, config, ... }:

{
  packages = with pkgs; [
    just
    wget
    nil
    yq-go
    (python3.withPackages (py-pkgs: with py-pkgs; [ huggingface-hub ]))
  ];

  # omp-model-sync.sh needs PI_CONFIG_FILES to know which overlay file to
  # write into. Home-manager's home.sessionVariables sets this for
  # *interactive login shells*, but that mechanism guards against
  # re-sourcing (`__HM_SESS_VARS_SOURCED`) once per login session, and the
  # native process manager's daemon snapshots its own environment once at
  # first start and keeps running independent of any shell's lifecycle --
  # both make it unreliable for a long-lived background process to inherit.
  # Set it directly here so it's always correct regardless of shell state.
  env.PI_CONFIG_FILES =
    if pkgs.stdenv.isDarwin then
      "${config.devenv.root}/files/omp/omp_darwin_config.yml"
    else
      "${config.devenv.root}/files/omp/omp_nixos_config.yml";

  processes.omp-model-sync = {
    exec = "bash \"$DEVENV_ROOT/bin/omp-model-sync.sh\"";
    watch = {
      paths = [ ./files/omp ];
      extensions = [
        "yml"
        "yaml"
      ];
    };
  };
}
