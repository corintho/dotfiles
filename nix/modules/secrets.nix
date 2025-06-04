{ secrets, options, paths, ... }: {
  age.identityPaths = options.age.identityPaths.default
    ++ [ "${paths.rootPath}/bootstrap.age" ];
  age.secrets.smb_corintho.file = "${secrets}/encrypted/smb_corintho.age";
}

