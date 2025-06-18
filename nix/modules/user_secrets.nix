{ config, secrets, options, paths, ... }: {
  # Secrets decrypted with user secret
  age.identityPaths = options.age.identityPaths.default
    ++ [ "${paths.rootPath}/bootstrap.age" ];
  age.secrets.known_hosts = {
    file = "${secrets}/encrypted/personal/known_hosts.age";
    # Have to set the path this way, cannot use `home.file` nor `xdg.configFile`
    path = config.home.homeDirectory + "/.ssh/known_hosts";
  };
  age.secrets."home.conf" = {
    file = "${secrets}/encrypted/personal/ssh_home.age";
    # Have to set the path this way, cannot use `home.file` nor `xdg.configFile`
    path = config.home.homeDirectory + "/.ssh/home.conf";
  };
  age.secrets."id_ed25519.pub" = {
    file = "${secrets}/encrypted/personal/id_ed25519.pub";
    # Have to set the path this way, cannot use `home.file` nor `xdg.configFile`
    path = config.home.homeDirectory + "/.ssh/id_ed25519.pub";
  };
  age.secrets."id_ed25519" = {
    file = "${secrets}/encrypted/personal/id_ed25519";
    # Have to set the path this way, cannot use `home.file` nor `xdg.configFile`
    path = config.home.homeDirectory + "/.ssh/id_ed25519";
  };
}

