{ config, secrets, options, paths, ... }: {
  # Secrets decrypted with the host secret
  age.identityPaths = options.age.identityPaths.default
    ++ [ "${paths.rootPath}/bootstrap.age" ];
  age.secrets.smb_corintho.file =
    "${secrets}/encrypted/personal/smb_corintho.age";
}

