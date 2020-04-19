(require 'ox-hugo)

(org-export-define-derived-backend 'blorf 'hugo
  :options-alist
  '((:hugo-base-dir "BLORF_BASE_DIR" nil blorf-base-dir)
    (:blorf-bundle "BLORF_BUNDLE" nil nil))
  :filters-alist '((:filter-body . blorf-body-filter)))

(defun blorf-global-props (property &optional buffer)
  "Get the plists of global org properties of current buffer."
  (with-current-buffer (or buffer (current-buffer))
    (org-element-map (org-element-parse-buffer) 'keyword
      (lambda (el) (when (string-match property (org-element-property :key el))
                     (org-element-property :value el))))))

(defun blorf-global-props-split (property &optional buffer)
  (mapcan (lambda (val)
            (split-string val))
          (blorf-global-props property buffer)))

(defun blorf-export-recursive (buffer content-dir default-target)
  (with-current-buffer buffer
    (mapc
     (lambda (file)
       (message "[ox-blorf] Following INCLUDE: %s" file)
       (blorf-export-recursive (find-file-noselect file) content-dir default-target))
     (blorf-global-props-split "INCLUDE")))
  (blorf-export buffer content-dir default-target))

(defun blorf-export (buffer content-dir default-target)
  (let ((org-tags-exclude-from-inheritance '("post")))
    (with-current-buffer buffer
      (org-map-entries
       (lambda ()
         (let* ((name (org-get-heading t t t t))
                (post (concat (replace-regexp-in-string "[[:space:]]" "-" (downcase name)) ".md"))
                (file (expand-file-name
                       (or (org-entry-get (point) "EXPORT_FILE_NAME")
                           (concat (file-name-as-directory default-target) post))
                       content-dir)))
           (mkdir (file-name-directory file) t)
           (org-export-to-file 'blorf file
             nil t)
           (message "[ox-blorf] Created post: %s" file)))
       "+post"))))

(defun blorf-body-filter (body _backend info)
  (let* ((base-dir (plist-get info :hugo-base-dir))
         (list (org-hugo--delim-str-to-list (plist-get info :blorf-bundle))))
    (when list
      (dolist (src-path list)
        (unless (file-exists-p src-path)
          (error "[ox-blorf] File %S is missing" src-path))
        (let* ((dest-path (concat base-dir "/static/" src-path))
               (dest-path-dir (file-name-directory dest-path)))
          (unless (file-exists-p dest-path-dir)
            (mkdir dest-path-dir :parents))
          (when (file-newer-than-file-p src-path dest-path)
            (message "[ox-blorf] Copied file %S to %S" src-path dest-path)
            (copy-file src-path dest-path :ok-if-already-exists)))))))

(setq org-hugo-section "posts")
(setq blorf-default-file (getenv "HUGO_DEFAULT_FILE"))
(setq blorf-base-dir (getenv "HUGO_BASE_DIR"))
(setq blorf-content-dir (expand-file-name "content" blorf-base-dir))

(unless (file-directory-p blorf-base-dir)
  (error "[ox-blorf] Hugo directory does not exist: %s" blorf-content-dir))

;; NOTE: We do not edit the source files, so this is fine
(defun ask-user-about-lock (file opponent) nil)

(blorf-export-recursive
 (find-file-noselect blorf-default-file)
 blorf-content-dir
 "entries")

(message "[ox-blorf] Seemingly everything worked.")
