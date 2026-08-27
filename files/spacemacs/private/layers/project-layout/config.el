; -*- lexical-binding: t; -*-

;; Build the workspace template when a projectile project switch begins.
(add-hook 'projectile-before-switch-project-hook #'project-layout//before-project-switch)

;; After a perspective/layout is loaded (e.g. Emacs restart with auto-resume),
;; ghostel terminal buffers are dead and eyebrowse has swapped them for *scratch*
;; on load. Rebuild re-spawns them in place. We advise the two Spacemacs
;; functions that load eyebrowse for a perspective so repair runs after the
;; window configs are actually available.
(when (fboundp 'spacemacs/load-eyebrowse-after-loading-layout)
  (advice-add 'spacemacs/load-eyebrowse-after-loading-layout :after
              #'project-layout//ensure-after-load))
(when (fboundp 'spacemacs/load-eyebrowse-for-perspective)
  (advice-add 'spacemacs/load-eyebrowse-for-perspective :after
              #'project-layout//ensure-after-load))
