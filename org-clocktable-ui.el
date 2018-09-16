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

(defun org-clocktable-ui--calculate-preview (parameters)
  "Calculate the clocktable heading for PARAMETERS."
  (setq res "#+BEGIN: clocktable")
  
  (if (plist-member parameters :maxlevel)
    (setq res (concat res (format " :maxlevel %s" (plist-get parameters :maxlevel)))))
  (if (plist-member parameters :match)
    (setq res (concat res (format " :match \"%s\"" (plist-get parameters :match)))))
  res)

(defun org-clocktable-ui--update-preview (preview parameters)
  "Set the PREVIEW widget for PARAMETERS."
  (widget-value-set preview (org-clocktable-ui--calculate-preview parameters)))

(defun org-clocktable-ui--show-configure-buffer (buffer beginning original-parameters)
  "Create the configuration form for BUFFER.
BEGINNING the position there and
ORIGINAL-PARAMETERS the org-kanban parameters."
  (switch-to-buffer "*org-clocktable-ui-configure*")
  (let (
         (parameters (copy-sequence original-parameters))
         (inhibit-read-only t)
         (preview nil))
    (erase-buffer)
    (remove-overlays)
    
    (widget-insert (propertize "Maxlevel: " 'face 'font-lock-keyword-face))
    (widget-create 'editable-field
      :value (format "%s" (or (plist-get parameters :maxlevel) 2))
      :size 5
      :notify (lambda (widget &rest ignore)
                (plist-put parameters :maxlevel (string-to-number (widget-value widget)))
                (org-clocktable-ui--update-preview preview parameters)))
    (widget-insert "\n")
    (widget-insert (propertize "  Maximum level depth to which times are listed in the table.\n  Clocks at deeper levels will be summed into the upper level." 'face 'font-lock-doc-face))
    (widget-insert "\n")

    (widget-insert "\n")
    (widget-insert (propertize "Match: " 'face 'font-lock-keyword-face))
    (widget-create 'editable-field
      :value (or (plist-get parameters :match) "")
      :size 5
      :notify (lambda (widget &rest ignore)
                (plist-put parameters :match (widget-value widget))
                (org-clocktable-ui--update-preview preview parameters)))
    (widget-insert "\n")
    (widget-insert (propertize "  see https://orgmode.org/manual/Matching-tags-and-properties.html#Matching-tags-and-properties on how to match tags e.g.: urgent|important" 'face 'font-lock-doc-face))
    (widget-insert "\n")

    (widget-insert "\n")
    (widget-insert (propertize "Result: " 'face 'font-lock-keyword-face))
    (setq preview
      (widget-create 'const))

    (widget-create 'push-button
      :notify (lambda(widget &rest ignore)
                (with-current-buffer buffer
                  (goto-char beginning)
                  (kill-line)
                  (insert (org-clocktable-ui--calculate-preview parameters)))
                (kill-buffer)
                (org-ctrl-c-ctrl-c))
      (propertize "Apply" 'face 'font-lock-comment-face))
    (widget-insert " ")
    (widget-create 'push-button
      :notify (lambda (widget &rest ignore)
                (kill-buffer))
      (propertize "Cancel" 'face 'font-lock-string-face))
    
    (org-clocktable-ui--update-preview preview parameters)
    (use-local-map widget-keymap)
    (widget-setup)))

;;;###autoload
(defun org-clocktable-ui-initialize (&optional arg)
  "Create an org-clocktable dynamic block at position ARG."
  (interactive "p")
  (cond (
          (eq arg nil) (org-clocktable-ui-initialize-here))
    ((eq arg 1) (org-clocktable-ui-initialize-here))
    ((eq arg 4) (org-clocktable-ui-initialize-at-beginning))
    ((eq arg 16) (org-clocktable-ui-initialize-at-end))
    (t (error (message "Unsupported universal argument %s" arg)))))

;;;###autoload
(defun org-clocktable-ui-initialize-at-beginning ()
  "Create an org-clocktable dynamic block at the beginning of the buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (forward-line)
    (org-clocktable-ui--initialize-at-point)))

;;;###autoload
(defun org-clocktable-ui-initialize-at-end ()
  "Create an org-clocktable-ui dynamic block at the end of the buffer."
  (interactive)
  (save-excursion
    (goto-char (point-max))
    (newline)
    (org-clocktable-ui--initialize-at-point)))

(defun org-clocktable-ui--initialize-at-point ()
  "Create an org-clocktable dynamic block at the point."
  (save-excursion
    (insert "#+BEGIN: clocktable :maxlevel 10\n#+END:\n"))
  (org-ctrl-c-ctrl-c))

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
