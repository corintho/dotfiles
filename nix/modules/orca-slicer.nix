{ appimageTools, fetchurl, lib, writeText, ... }:
let
  pname = "OrcaSlicer";
  version = "2.3.2-beta2";

  src = fetchurl {
    url =
      "https://github.com/OrcaSlicer/OrcaSlicer/releases/download/v${version}/OrcaSlicer_Linux_AppImage_Ubuntu2404_V${version}.AppImage";
    hash = "sha256-8IDF6NOzGW0RNO5duprCFNuVoItjv/xSrRILmw0yjZ4=";
  };

  appimageContents = appimageTools.extractType1 { inherit pname version src; };

  orcaslicer-launcher-desktop = writeText "orcaslicer-launcher.desktop" ''
    [Desktop Entry]
    Categories=Utility
    Exec=OrcaSlicer %U
    Icon=OrcaSlicer
    MimeType=model/stl;model/3mf;application/vnd.ms-3mfdocument;application/prs.wavefront-obj;application/x-amf;x-scheme-handler/orcaslicer
    Name=OrcaSlicer-AppImage
    Terminal=false
    Type=Application
    Version=1.5
  '';
in appimageTools.wrapType2 {
  inherit pname version src;

  extraBwrapArgs = [ "--setenv GTK_THEME Adwaita:dark" ];

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    ln -s ${orcaslicer-launcher-desktop} $out/share/applications/OrcaSlicer-AppImage.desktop
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  extraPkgs = pkgs: with pkgs; [ webkitgtk_4_1 ];

  meta = {
    description = "Orca slicer";
    homepage = "https://www.orcaslicer.com/";
    downloadPage = "https://github.com/OrcaSlicer/OrcaSlicer/releases";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ corintho ];
    mainProgram = "OrcaSlicer";
    platforms = [ "x86_64-linux" ];
  };
}
