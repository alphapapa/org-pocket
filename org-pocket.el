;;; org-pocket.el --- Tools to use Pocket with Org  -*- lexical-binding: t; -*-


;;; Commentary:

;; This requires the `ap/pocket-api' package, which is a fork of
;; `pocket-api': <https://github.com/alphapapa/pocket-api.el>

;;; Code:

(require 'ap/pocket-api)

(require 'org-web-tools)

;;;; Variables

(defgroup org-pocket nil
  "Settings for `org-pocket'.")

(defcustom org-pocket-capture-position nil
  "Whether items are captured at the top or bottom of the capture file."
  :type '(radio (const :tag "Top" 0)
                (const :tag "Bottom" nil)))

(defcustom org-pocket-capture-file ""
  "`org-pocket-capture-items' will capture items to this file."
  :type '(file :must-match t))

(defcustom org-pocket-capture-tag "capture"
  "Items with this tag will be captured by `org-pocket-capture-items'."
  :type 'string)

;;;; Functions

;; These functions operate on "items", each of which is a list in the
;; form (ID (KEY . VALUE) ...), which are parsed out of the JSON
;; response from Pocket.

;;;;; Commands

;;;###autoload
(cl-defun org-pocket-capture-items (&key (archive t))
  "Capture Pocket items that are unarchived and tagged with `org-pocket-capture-tag' to `org-pocket-capture-file'.
Items will be archived unless ARCHIVE is nil.  A maximum of 10
items are captured at a time."
  (interactive)
  (unless org-pocket-capture-file
    (user-error "Please set `org-pocket-capture-file'"))
  (unless org-pocket-capture-tag
    (user-error "Please set `org-pocket-capture-tag'"))
  (when-let ((file org-pocket-capture-file)
             (items (alist-get 'list (pocket-api--get :tag org-pocket-capture-tag))))
    (cl-loop for item in items
             when (org-pocket--capture-item item :file file)
             sum 1 into count
             and when archive
             collect item into to-archive
             finally do (when to-archive
                          (apply #'pocket-api--archive to-archive))
             finally do (message "Captured %s items" count))))

;;;;; Helpers

(cl-defun org-pocket--capture-item (item &key file)
  (when-let ((url (alist-get 'resolved_url item))
             (rfloc (list nil file nil org-pocket-capture-position)))
    (with-temp-buffer
      (org-mode)
      (when (org-web-tools-insert-web-page-as-entry url)
        ;; FIXME: Not sure that this will actually return nil if it doesn't work
        (goto-char (point-min))
        (org-refile nil nil rfloc)))))

;;;; Footer

(provide 'org-pocket)

;;; org-pocket.el ends here
