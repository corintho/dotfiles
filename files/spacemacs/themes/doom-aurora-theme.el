;;; doom-aurora-theme.el --- neon dark theme matching the oh-my-pi dark-aurora palette -*- lexical-binding: t; no-byte-compile: t; -*-
;;
;; Source: oh-my-pi `dark-aurora' theme (can1357/oh-my-pi,
;; packages/tui/src/theme/defaults.json) and its `terminal' ANSI palette.
;; The orange has no upstream equivalent; it is borrowed from humanoid-dark.
;;
;;; Commentary:
;; Keeps the same hues as files/dark-aurora.yaml (stylix) so terminal, WM and
;; Emacs agree.  Palette names follow `def-doom-theme' so `doom-color' (used by
;; the TODO-state colors in init.org) keeps working.
;;; Code:

(require 'doom-themes)


;;
;;; Variables

(defgroup doom-aurora-theme nil
  "Options for doom-themes."
  :group 'doom-themes)

(defcustom doom-aurora-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds a 4px padding to the mode-line.
Can be an integer to determine the exact padding."
  :group 'doom-aurora-theme
  :type '(choice integer boolean))


;;
;;; Theme definition

(def-doom-theme doom-aurora
  "A neon theme on a blue-black background, after oh-my-pi's dark-aurora."

  ;; name        default   256       16
  ((bg         '("#0f0f1a" "#0f0f1a" nil           ))
   (bg-alt     '("#0a0a12" "#0a0a12" nil           ))
   (base0      '("#0a0a12" "#0a0a12" "black"       ))
   (base1      '("#131320" "#131320" "brightblack" ))
   (base2      '("#1a1a2e" "#1a1a2e" "brightblack" ))
   (base3      '("#2a2a3e" "#2a2a3e" "brightblack" ))
   (base4      '("#3a3a52" "#3a3a52" "brightblack" ))
   (base5      '("#6c6c86" "#6c6c86" "brightblack" ))
   (base6      '("#8a8aa4" "#8a8aa4" "brightblack" ))
   (base7      '("#c0c0d0" "#c0c0d0" "brightblack" ))
   (base8      '("#e8e8f4" "#e8e8f4" "white"       ))
   (fg-alt     '("#a0a0b8" "#a0a0b8" "white"       ))
   (fg         '("#d8d8e8" "#d8d8e8" "brightwhite" ))

   (grey       base5)
   (red        '("#ff0055" "#ff0055" "red"          ))
   (orange     '("#ff9505" "#ff9505" "brightred"    ))
   (green      '("#00ff9f" "#00ff9f" "green"        ))
   (teal       '("#00e8c6" "#00e8c6" "brightgreen"  ))
   (yellow     '("#ffee00" "#ffee00" "yellow"       ))
   (blue       '("#00b4d8" "#00b4d8" "brightblue"   ))
   (dark-blue  '("#3a8dff" "#3a8dff" "blue"         ))
   (magenta    '("#d45cff" "#d45cff" "magenta"      ))
   (violet     '("#bd00ff" "#bd00ff" "brightmagenta"))
   (cyan       '("#33dcf0" "#33dcf0" "brightcyan"   ))
   (dark-cyan  '("#0b2a30" "#0b2a30" "cyan"         ))

   ;; face categories -- required for all themes
   (highlight      violet)
   (vertical-bar   base3)
   (selection      base4)
   (builtin        dark-blue)
   (comments       base6)
   (doc-comments   fg-alt)
   (constants      orange)
   (functions      yellow)
   (keywords       blue)
   (methods        yellow)
   (operators      base5)
   (type           violet)
   (strings        red)
   (variables      teal)
   (numbers        green)
   (region         base4)
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    orange)
   (vc-added       green)
   (vc-deleted     red)

   ;; custom categories
   (hidden     `(,(car bg) "black" "black"))
   (-modeline-pad
    (when doom-aurora-padded-modeline
      (if (integerp doom-aurora-padded-modeline) doom-aurora-padded-modeline 4)))

   (modeline-fg     fg)
   (modeline-fg-alt base5)

   (modeline-bg            base2)
   (modeline-bg-l          base2)
   (modeline-bg-inactive   base1)
   (modeline-bg-inactive-l base1))


  ;;;; Base theme face overrides
  (((font-lock-comment-face &override) :slant 'italic)
   ((font-lock-keyword-face &override) :weight 'bold)
   ((line-number &override) :foreground base4)
   ((line-number-current-line &override) :foreground fg)
   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-inactive :foreground modeline-fg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
   (mode-line-emphasis :foreground highlight)
   (mode-line-highlight :background violet :foreground bg :weight 'bold)
   (vertical-border :foreground base3)

   ;;;; company
   (company-tooltip-selection :background dark-cyan)
   (company-tooltip-common    :foreground violet :distant-foreground base0 :weight 'bold)
   ;;;; doom-modeline
   (doom-modeline-bar :background violet)
   ;;;; markdown-mode
   (markdown-markup-face :foreground base5)
   (markdown-header-face :inherit 'bold :foreground teal)
   (markdown-url-face    :foreground base5 :weight 'normal)
   (markdown-code-face   :foreground violet)
   ((markdown-bold-face &override)   :foreground fg)
   ((markdown-italic-face &override) :foreground fg-alt)
   ;;;; outline <built-in>
   ((outline-1 &override) :foreground teal)
   ((outline-2 &override) :foreground blue)
   ((outline-3 &override) :foreground violet)
   ((outline-4 &override) :foreground green)
   ((outline-5 &override) :foreground yellow)
   ((outline-6 &override) :foreground orange)
   ((outline-7 &override) :foreground magenta)
   ((outline-8 &override) :foreground cyan)
   ;;;; org <built-in>
   ((org-block &override) :background base0)
   ((org-block-begin-line &override) :background base0)
   (org-hide              :foreground hidden)
   ;;;; solaire-mode
   (solaire-mode-line-face
    :inherit 'mode-line
    :background modeline-bg-l
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-l)))
   (solaire-mode-line-inactive-face
    :inherit 'mode-line-inactive
    :background modeline-bg-inactive-l
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-l))))

  ;;;; Base theme variable overrides-
  ;; ()
  )

;;; doom-aurora-theme.el ends here
