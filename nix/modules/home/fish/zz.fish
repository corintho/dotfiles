function zz --argument layout
    set -q layout[1]; or set -l layout "zellij.kdl"
    set -l session (path basename $PWD)
    set -f layout_param
    if test -f "$layout"
        set -f layout_param --layout $layout
    else
        echo "Layout file: '$layout' not found"
    end
    zellij $layout_param attach --create $session
end
