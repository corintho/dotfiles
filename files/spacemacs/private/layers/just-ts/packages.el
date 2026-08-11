;; -*- mode: emacs-lisp; lexical-binding: t -*-
;;; packages.el --- just-ts layer packages file for Spacemacs

;;; Commentary:
;; Provides just-ts-mode for editing Justfiles, backed by a tree-sitter parser.
;; The package registers its auto-mode-alist entry via autoloads, so no
;; explicit :mode wiring is needed here.  The :config block installs the
;; tree-sitter grammar on first load if it is not already present.

;;; Code:

(defconst just-ts-packages
  '(just-ts-mode))

(defun just-ts/init-just-ts-mode ()
  "Initialize just-ts-mode."
  (use-package just-ts-mode
    :defer t
    :config
    (unless (treesit-language-available-p 'just)
      (just-ts-mode-install-grammar))))

;;; packages.el ends here
