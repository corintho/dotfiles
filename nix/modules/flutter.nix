{
  nixpkgs,
  local_flutter_path,
  flutter_version,
}:
# Downloads flutter into a local directory (passed as local_flutter_path) and returns the bin path so the calling shellHook can set it to the PATH
# call (e.g. in ShellHook) with
#   ${flutter-local.unpack_flutter}/bin/unpack_flutter
#   export PATH="${local_flutter_path}/flutter/bin:$PATH"
# add a new flutter version:
# check the url in https://docs.flutter.dev/release/archive?tab=macos
# leave `hash = ""` and run `nix develop`. The error message will tell the correct hash value.
let
  pkgs = import nixpkgs { };
in
rec {
  latest_version = "3.47.6";
  desired_version =
    if (flutter_version == null || flutter_version == "latest") then
      latest_version
    else
      flutter_version;

  flutter_source =
    if desired_version == "3.47.6" then
      pkgs.fetchurl {
        url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.47.6-stable.zip";
        hash = "sha256-oZRtO2s94VziR9yJZJ35A1zinmtOfr6RkZoliQ6i55o=";
      }
    else if desired_version == "3.38.4" then
      pkgs.fetchurl {
        url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.38.4-stable.zip";
        hash = "sha256-JcbMFJb3MGtKd93IBAP5YNAlt/P2bZQ0+ZyiEsuDDD8=";
      }
    else
      "Unknown flutter version: ${desired_version}";

  unpack_flutter = pkgs.writeShellApplication {
    name = "unpack_flutter";
    runtimeInputs = with pkgs; [
      git
      unzip
      which
    ];

    text = ''
      flutter_bin_dir="${local_flutter_path}"/flutter/bin
      flutter_bin_file="$flutter_bin_dir"/flutter

      echo "flutter needs local installation? ..."
      if [ -f "$flutter_bin_file" ]; then
        local_flutter_version=$( $flutter_bin_file --version | grep -oP 'Flutter \K.*(?= • channel)')
        if [ "$local_flutter_version" = "${desired_version}" ]; then
          echo "flutter $local_flutter_version is already installed locally in '${local_flutter_path}'"
          install=false
        else
          echo "flutter is already installed locally, but the installed version '$local_flutter_version' is not the same as requested version '${desired_version}'.  Uninstalling..."
          rm -rf "${local_flutter_path}"
          install=true
        fi
      else
        install=true
      fi
      if [ "$install" = "true" ]; then
        echo "... installing flutter version '${desired_version}' locally in '${local_flutter_path}'"
        unzip "${flutter_source}" -d "${local_flutter_path}"
        echo "installed flutter version '${desired_version}' to '${local_flutter_path}'"
      fi
    '';
  };
}
