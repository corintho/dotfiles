function zz --argument layout
  set -q layout[1]; or set layout "zellij.kdl"
  if test -f "$layout"
    zellij --layout $layout
  else
    echo "Layout file: '$layout' not found"
  end
end
