{ secrets, options, paths, ... }: {
  age.identityPaths = options.age.identityPaths.default
    ++ [ "${paths.rootPath}/bootstrap.age" ];
  age.secrets.smb_corintho.file =
    "${secrets}/encrypted/personal/smb_corintho.age";
}

