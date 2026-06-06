{ appimageTools, fetchurl, lib, writeText, ... }:
let
  pname = "freecad";
  version = "1.1rc2";

  src = fetchurl {
    url =
      "https://github.com/FreeCAD/FreeCAD/releases/download/${version}/FreeCAD_${version}-Linux-x86_64-py311.AppImage";
    hash = "sha256-xyYgbpnvcofS/zp+wDa3q87KLrBAq/PXjelGl4mHYww=";
  };
  appimageContents = appimageTools.extractType1 { inherit pname version src; };
  freecad-launcher-desktop = writeText "freecad-rc-launcher.desktop" ''
    [Desktop Entry]
    Categories=Utility
    Exec=freecad %U
    Icon=FreeCAD
    Name=FreeCAD RC
    Terminal=false
    Type=Application
    Version=1.5
  '';
in appimageTools.wrapType2 {
  inherit pname version src;
  # pkgs = pkgs;
  extraInstallCommands = ''
      mkdir -p $out/share/applications
      ln -s ${freecad-launcher-desktop} $out/share/applications/FreeCAD-RC.desktop
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  extraPkgs = pkgs: with pkgs; [ ];

  meta = {
    description = "Free Cad";
    homepage = "https://www.freecad.org/";
    downloadPage = "https://github.com/FreeCAD/FreeCAD/releases";
    license = lib.licenses.lgpl21;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ corintho ];
    mainProgram = "freecad";
    platforms = [ "x86_64-linux" ];
  };
}
