{
  stdenv,
  fetchurl,
  lib,
  makeWrapper,
  appimageTools,
}:

let
  pname = "markpad";
  version = "2.6.12";

  meta = {
    description = "The Notepad equivalent for Markdown";
    longDescription = ''
      Markpad is a lightweight markdown editor with split view,
      GitHub Flavored Markdown, LaTeX support, Mermaid diagrams,
      and Vim mode.
    '';
    homepage = "https://markpad.sftwr.dev/";
    downloadPage = "https://github.com/alecdotdev/Markpad/releases";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    maintainers = with lib.maintainers; [ corintho ];
  };
in

if stdenv.hostPlatform.isDarwin then
  stdenv.mkDerivation rec {
    inherit pname version meta;

    src = fetchurl {
      url = "https://github.com/alecdotdev/Markpad/releases/download/v${version}/Markpad.app.tar.gz";
      hash = "sha256-5UfpyssEu6FjOYjBGjbTsV12M71gpIOOyVFotqKxSTE=";
    };

    nativeBuildInputs = [ makeWrapper ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/Applications
      cp -r Markpad.app $out/Applications/

      # Create a CLI wrapper for convenience
      mkdir -p $out/bin
      makeWrapper $out/Applications/Markpad.app/Contents/MacOS/Markpad \
        $out/bin/markpad
    '';
  }
else
  appimageTools.wrapType2 {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/alecdotdev/Markpad/releases/download/v${version}/Markpad_${version}_amd64.AppImage";
      hash = "sha256-3DSrrWkTnMilIt359MgtLRNlx66Aqoh6+kW9IBBJCfQ=";
    };

    meta = meta // {
      platforms = [ "x86_64-linux" ];
    };
  }
