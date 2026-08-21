(defun project-layout//code-buffer (root)
  "Return the buffer to display in the code workspace of project ROOT."
  (if (and (current-buffer)
           (projectile-project-buffer-p (current-buffer) root))
      (current-buffer)
    (or (car (projectile-project-buffers root))
        (dired root)
        (current-buffer))))

(defun project-layout//layout-code (root)
  "Arrange the code workspace for project ROOT."
  (delete-other-windows)
  (switch-to-buffer (project-layout//code-buffer root)))

(defun project-layout//layout-terms (root)
  "Arrange the terms workspace for project ROOT: two ghostel terminals."
  (delete-other-windows)
  (let ((default-directory (file-name-as-directory root)))
    (switch-to-buffer (ghostel-project 1)))
  (split-window-right)
  (other-window 1)
  (let ((default-directory (file-name-as-directory root)))
    (switch-to-buffer (ghostel-project 2))))

(defun project-layout//layout-chat (root)
  "Arrange the chat workspace for project ROOT: a single ghostel terminal."
  (delete-other-windows)
  (let ((default-directory (file-name-as-directory root)))
    (switch-to-buffer (ghostel-project 3))))

(defun project-layout//build-template (root persp)
  "Build the code/terms/chat workspace template for project layout PERSP."
  (let ((eyebrowse-new-workspace nil))
    (let ((code-slot (eyebrowse--get 'current-slot)))
      (project-layout//layout-code root)
      (eyebrowse-rename-window-config code-slot "code")
      (let ((terms-slot (spacemacs//workspace-next-free-slot)))
        (eyebrowse-switch-to-window-config terms-slot)
        (project-layout//layout-terms root)
        (eyebrowse-rename-window-config terms-slot "terms")
        (let ((chat-slot (spacemacs//workspace-next-free-slot)))
          (eyebrowse-switch-to-window-config chat-slot)
          (project-layout//layout-chat root)
          (eyebrowse-rename-window-config chat-slot "chat")
          (eyebrowse-switch-to-window-config code-slot))))
    (set-persp-parameter 'project-layout-workspaces-built t persp)
    ;; Persist immediately. Ghostel terminals die on restart and eyebrowse swaps
    ;; them for *scratch* on load; also `layouts-autosave-delay' (60s) may not
    ;; have flushed yet. Forcing the save keeps the template intact across a
    ;; restart that happens sooner than the autosave interval.
    (spacemacs/save-eyebrowse-for-perspective)
    (persp-save-state-to-file)))

(defun project-layout//before-project-switch ()
  "Build the workspace template when a projectile project switch begins."
  (let* ((persp (get-current-persp))
         (persp-name (safe-persp-name persp))
         (root (and persp-name (file-truename (expand-file-name persp-name)))))
    (when (and root
               (file-directory-p root)
               (not (persp-parameter 'project-layout-workspaces-built persp)))
      (condition-case err
          (project-layout//build-template root persp)
        (error (message "project-layout: template build error: %s"
                        (error-message-string err)))))))

(defun project-layout//workspace-terminals-live-p ()
  "Return non-nil if the terms (2) and chat (3) workspaces hold live ghostel terminals."
  (let ((configs (eyebrowse--get 'window-configs))
        (current (eyebrowse--get 'current-slot))
        (ok t))
    (dolist (slot '(2 3))
      (when (assq slot configs)
        (eyebrowse-switch-to-window-config slot)
        (dolist (win (window-list))
          (let ((buf (window-buffer win)))
            (unless (and (buffer-live-p buf)
                         (with-current-buffer buf
                           (derived-mode-p 'ghostel-mode)))
              (setq ok nil))))
        (eyebrowse-switch-to-window-config current)))
    ok))

(defun project-layout//rebuild (root persp)
  "Force the code/terms/chat template at fixed slots 1/2/3 with live ghostel terminals.
Reuses the same `ghostel-project' calls as `project-layout//build-template'."
  (let ((eyebrowse-new-workspace nil))
    (eyebrowse-switch-to-window-config 1)
    (project-layout//layout-code root)
    (eyebrowse-rename-window-config 1 "code")
    (eyebrowse-switch-to-window-config 2)
    (project-layout//layout-terms root)
    (eyebrowse-rename-window-config 2 "terms")
    (eyebrowse-switch-to-window-config 3)
    (project-layout//layout-chat root)
    (eyebrowse-rename-window-config 3 "chat")
    (eyebrowse-switch-to-window-config 1))
  (set-persp-parameter 'project-layout-workspaces-built t persp)
  (spacemacs/save-eyebrowse-for-perspective)
  (persp-save-state-to-file))

(defun project-layout//ensure (persp)
  "Ensure PERSP's terms/chat workspaces hold live terminals; rebuild if not."
  (let ((root (and (stringp (safe-persp-name persp))
                   (file-truename (expand-file-name (safe-persp-name persp))))))
    (when (and root (file-directory-p root)
               (persp-parameter 'project-layout-workspaces-built persp))
      (condition-case err
          (unless (and (assq 2 (eyebrowse--get 'window-configs))
                       (assq 3 (eyebrowse--get 'window-configs))
                       (project-layout//workspace-terminals-live-p))
            (message "project-layout: rebuilding terminals for %s"
                     (safe-persp-name persp))
            (project-layout//rebuild root persp))
        (error (message "project-layout: rebuild failed: %s"
                        (error-message-string err)))))))

(defun project-layout//ensure-after-load (&rest _)
  "Ensure live terminals in the current project-layout persp after layout resume.
Intended as an :after advice on Spacemacs's eyebrowse-load functions, which fire
when a perspective/layout is loaded (e.g. Emacs startup with auto-resume)."
  (let ((cur (get-current-persp)))
    (when (and cur (persp-parameter 'project-layout-workspaces-built cur))
      (project-layout//ensure cur))))

;;; funcs.el ends here
