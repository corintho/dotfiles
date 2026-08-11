;; -*- mode: emacs-lisp; lexical-binding: t -*-
;;; packages.el --- direnv layer configuration file for Spacemacs

;;; Commentary:
;; Spacemacs does not ship a direnv layer, so this private layer provides
;; one. It enables `direnv-mode', which loads the environment from a project's
;; .envrc into each buffer of the project via emacs-direnv.

;;; Code:

(defconst direnv-packages
  '(direnv))

(defun direnv/init-direnv ()
  "Initialize direnv."
  (use-package direnv
    :defer t
    :init
    (direnv-mode)))

;;; packages.el ends here
