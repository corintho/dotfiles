{
  pkgs,
  system,
}:
let
  lib = pkgs.lib;
  npmMirror = builtins.getEnv "DOTFILES_NPM_MIRROR";
  version = "2.0.11";

  # `@opencode/cli` (the npm meta-package) ships no payload itself; the real
  # binary lives in a per-platform optionalDependency package, each
  # containing exactly `package.json` + a single prebuilt `bin/opencode`
  # executable (verified via npm registry file listing for both platform
  # packages at 2.0.11: no other files, no further dependencies).
  platformPackage =
    {
      aarch64-darwin = "cli-darwin-arm64";
      x86_64-linux = "cli-linux-x64";
    }
    .${system} or (throw "opencode-cli-package.nix: unsupported system ${system}");

  # Real sha256 hashes for the opencode-cli 2.0.11 platform packages,
  # computed via `nix store prefetch-file --unpack` against the corporate
  # npm mirror (`DOTFILES_NPM_MIRROR`, see `nix/corporate.env`).
  platformHash =
    {
      aarch64-darwin = "sha256-8vzEgCu4Gk8Mxm459/rnOwRKclnkSPPHN5FhRT+GTMA=";
      x86_64-linux = "sha256-7k9B4dOZZem/nrY7gjyPHh3D8GBtwPRsJjNmIIYZmeg=";
    }
    .${system};

  opencodeBinary = pkgs.fetchzip {
    urls =
      lib.optional (
        npmMirror != ""
      ) "${npmMirror}/@opencode/${platformPackage}/-/${platformPackage}-${version}.tgz"
      ++ [
        "https://registry.npmjs.org/@opencode/${platformPackage}/-/${platformPackage}-${version}.tgz"
      ];
    sha256 = platformHash;
  };
in
pkgs.stdenv.mkDerivation {
  pname = "opencode-cli";
  inherit version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  # Stripping can corrupt a Bun-compiled executable's embedded runtime/
  # codesign; nixpkgs' own `opencode` and `claude-code` packages both set
  # this for the same reason.
  dontStrip = true;

  nativeBuildInputs = [
    pkgs.makeWrapper
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.darwin.sigtool ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isElf [ pkgs.autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${opencodeBinary}/bin/opencode $out/bin/opencode
    wrapProgram $out/bin/opencode \
      --set OPENCODE_DISABLE_AUTOUPDATE true \
      --prefix PATH : ${
        lib.makeBinPath (
          [ pkgs.ripgrep ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.sysctl ]
        )
      }
    runHook postInstall
  '';

  postInstall = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
    codesign --force --sign - $out/bin/.opencode-wrapped
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    pkgs.versionCheckHook
    pkgs.writableTmpDirAsHomeHook
  ];
  versionCheckProgramArg = "--version";
  versionCheckKeepEnvironment = [ "HOME" ];

  meta = {
    description = "AI coding agent built for the terminal (npm-distributed opencode v2 binary)";
    homepage = "https://github.com/anomalyco/opencode";
    license = lib.licenses.mit;
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    mainProgram = "opencode";
  };
}
