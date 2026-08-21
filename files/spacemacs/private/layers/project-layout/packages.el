;; -*- mode: emacs-lisp; lexical-binding: t -*-
;;; packages.el --- project-layout layer configuration file for Spacemacs

;;; Commentary:
;; Auto-builds a "code / terms / chat" workspace template inside each freshly
;; created project layout (created with `SPC p l').  Persistence is handled by
;; the spacemacs-layouts layer: eyebrowse workspaces are stored as persp
;; parameters and saved by the layouts autosave.  This layer ships no packages
;; of its own; it composes persp-mode, eyebrowse and ghostel provided by the
;; spacemacs-layouts and shell layers.

;;; Code:

(defconst project-layout-packages
  '())

;;; packages.el ends here