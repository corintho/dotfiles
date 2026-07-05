{ appimageTools, fetchurl, lib, writeText, calculix-ccx, ... }:
let
  pname = "freecad";
  version = "1.1.1";

  src = fetchurl {
    url = "https://github.com/FreeCAD/FreeCAD/releases/download/${version}/FreeCAD_${version}-Linux-x86_64-py311.AppImage";
    hash = "sha256-4gBhOEALL6hfouFg6HLQB2frMpZOhQdYMPfhmKOoduE=";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
  freecad-desktop = writeText "freecad.desktop" ''
    [Desktop Entry]
    Categories=Engineering;Graphics;
    Exec=freecad %U
    GenericName=CAD Application
    Icon=freecad
    Name=FreeCAD
    Terminal=false
    Type=Application
  '';
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands =
    let
      desktopDir = "${appimageContents}/usr/share";
    in
    ''
      mkdir -p $out/share/applications $out/share/icons
      cp -r ${desktopDir}/icons/* $out/share/icons/
      cp ${freecad-desktop} $out/share/applications/freecad.desktop
    '';

  extraPkgs = pkgs: with pkgs; [ calculix-ccx ];

  meta = {
    description = "Free and open-source parametric 3D CAD modeler";
    homepage = "https://www.freecad.org/";
    downloadPage = "https://github.com/FreeCAD/FreeCAD/releases";
    license = lib.licenses.lgpl21;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ corintho ];
    mainProgram = "freecad";
    platforms = [ "x86_64-linux" ];
  };
}
