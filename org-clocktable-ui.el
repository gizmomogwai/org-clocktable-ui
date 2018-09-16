;;; org-clocktable-ui --- Simple ui to configure org clocktables. -*- lexical-binding: t -*-
;; Copyright (C) 2018 Christian Köstlin

;; This file is NOT part of GNU Emacs.

;; Author: Christian Köstlin <christian.koestlin@gmail.com>
;; Keywords: org-mode, org, tools
;; Package-Requires: ((dash "2.13.0") (emacs "24.4") (org "9.1"))
;; Package-Version: 0.0.1
;; Homepage: http://github.com/gizmomogwai/org-clocktable-ui

;;; Commentary:
;; Call `org-clocktable-ui-configure when' you are inside a clocktable
;; see https://orgmode.org/manual/The-clock-table.html for all available parameters

(require 'org)
(require 'dash)
(require 'widget)

;;; Code:

(defun org-clocktable-ui--calculate-preview (maxlevel)
  "Calculate the clocktable heading for MAXLEVEL."
  (setq res "#+BEGIN: clocktable")
  (if maxlevel
    (setq res (concat res " :maxlevel " maxlevel)))
  res)

(defun org-clocktable-ui--update-preview (preview maxlevel)
  "Set the PREVIEW widget for MAXLEVEL."
  (widget-value-set preview (org-clocktable-ui--calculate-preview maxlevel)))

(defun org-clocktable-ui--show-configure-buffer (buffer beginning parameters)
  "Create the configuration form for BUFFER.
BEGINNING the position there and
PARAMETERS the org-kanban parameters."
  (switch-to-buffer "*org-clocktable-ui-configure*")
  (let (
         (inhibit-read-only t)
         (maxlevel (format "%s" (or (plist-get parameters :maxlevel) 2)))
         (preview nil))
    (erase-buffer)
    (remove-overlays)
    (widget-insert (propertize "Maxlevel: " 'face 'font-lock-keyword-face))
    (widget-create 'editable-field
      :value maxlevel
      :size 5
      :notify (lambda (widget &rest ignore)
                (setq maxlevel (widget-value widget))
                (org-clocktable-ui--update-preview preview maxlevel)))
    (widget-insert "\n")
    (widget-insert (propertize "Result: " 'face 'font-lock-keyword-face))
    (setq preview
      (widget-create 'const))

    (widget-create 'push-button
      :notify (lambda(widget &rest ignore)
                (with-current-buffer buffer
                  (goto-char beginning)
                  (kill-line)
                  (insert (org-clocktable-ui--calculate-preview maxlevel)))
                (kill-buffer)
                (org-ctrl-c-ctrl-c))
      (propertize "Apply" 'face 'font-lock-comment-face))
    (widget-insert " ")
    (widget-create 'push-button
      :notify (lambda (widget &rest ignore)
                (kill-buffer))
      (propertize "Cancel" 'face 'font-lock-string-face))
    
    (org-clocktable-ui--update-preview preview maxlevel)
    (use-local-map widget-keymap)
    (widget-setup)))

;;;###autoload
(defun org-clocktable-ui-configure ()
  "Configure the current org-clocktable dynamic block."
  (interactive)
  (with-demoted-errors "Error: %S"
    (let* (
            (beginning (org-beginning-of-dblock))
            (parameters (org-prepare-dblock)))
      (org-clocktable-ui--show-configure-buffer (current-buffer) beginning parameters))))


(provide 'org-clocktable-ui)
;;; org-clocktable-ui.el ends here