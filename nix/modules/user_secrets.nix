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
}

