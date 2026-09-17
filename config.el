;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; Nerd Fonts
(setq doom-font (font-spec :family "JetBrains Mono" :size 16 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "JetBrains Mono" :size 17)
      doom-big-font (font-spec :family "JetBrains Mono" :size 24))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-gruvbox)
;; Specify both a dark and light theme, like so and Doom will choose which one
;; to load based on your system light/dark setting:
;;
;;   (setq doom-theme '(doom-one   . doom-one-light))   ; (DARK . LIGHT)
;;
;; If you want more pro-active theme switching based on OS light/dark mode, look
;; up the `auto-dark' package.

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

(after! org
  (setq org-startup-with-link-previews t)

  ;; Org ships C babel as ob-C.el (feature `ob-C'), not ob-c.
  ;; `#+begin_src c` otherwise makes Doom (require 'ob-c); on macOS that
  ;; loads ob-C.elc and then errors because the file provides `ob-C'.
  (add-to-list 'org-src-lang-modes '("c" . c))
  (after! ob-C
    (defalias 'org-babel-execute:c #'org-babel-execute:C)
    (defalias 'org-babel-expand-body:c #'org-babel-expand-body:C))

  (defadvice! +org--yank-image-preview-a (fn &rest args)
    "Insert clipboard images as description-less links and preview them."
    :around #'org--image-yank-media-handler
    (cl-letf (((symbol-function #'org-link-make-string-for-buffer)
               (lambda (link &optional _description &rest _)
                 (org-link-make-string link))))
      (apply fn args))
    (org-link-preview-refresh))

  (defun +org--delete-empty-attach-dirs (dir)
    "Delete DIR and empty parents up through `org-attach-id-dir'."
    (let* ((dir (directory-file-name (expand-file-name dir)))
           (root (directory-file-name
                  (expand-file-name
                   (or org-attach-id-dir
                       (expand-file-name ".attach/" org-directory))))))
      (unless (file-directory-p dir)
        (setq dir (directory-file-name (file-name-directory dir))))
      (while (and dir
                  (file-directory-p dir)
                  (org-directory-empty-p dir)
                  (> (length dir) (length root)))
        (delete-directory dir)
        (setq dir (directory-file-name (file-name-directory dir))))))

  (defun +org/delete-attachment-at-point ()
    "Delete the attachment/file link at point, including the file on disk."
    (interactive)
    (when-let ((ov (cdr (get-char-property-and-overlay (point) 'org-image-overlay))))
      (goto-char (overlay-start ov))
      (delete-overlay ov))
    (unless (org-in-regexp org-link-bracket-re 1)
      (user-error "No link at point"))
    (let* ((beg (copy-marker (match-beginning 0)))
           (end (copy-marker (match-end 0) t))
           (raw (match-string-no-properties 1))
           (type (and (string-match "\\`\\([^:]+\\):" raw)
                      (match-string 1 raw)))
           (path (and type (substring raw (match-end 0)))))
      (unless (member type '("attachment" "file"))
        (user-error "Not an attachment or file link"))
      (require 'org-attach)
      (let ((file (if (equal type "attachment")
                      (org-attach-expand path)
                    (expand-file-name path))))
        ;; Delete the link before any heading edits so positions stay valid.
        (delete-region beg end)
        (when (and (bolp) (eolp) (not (eobp)))
          (delete-char 1))
        (set-marker beg nil)
        (set-marker end nil)
        (when (and file (file-exists-p file))
          (delete-file file))
        (when (equal type "attachment")
          (when-let ((dir (and file (file-name-directory file))))
            (let ((last-p (or (not (file-directory-p dir))
                              (org-directory-empty-p dir))))
              (when last-p
                (+org--delete-empty-attach-dirs dir)
                (org-attach-untag))))))))

  (map! :map org-mode-map
        :localleader
        (:prefix ("a" . "attachments")
         "p" #'yank-media
         "k" #'+org/delete-attachment-at-point)))

(after! evil-org
  (map! :map evil-org-mode-map
        :n "zi" #'org-link-preview))

(setq org-roam-directory (file-truename "~/roam-notes")
      org-attach-id-dir (expand-file-name ".attach/" org-roam-directory))

;; Emacs 31.1 man.el does not interpret groff 1.24 OSC 8 hyperlinks.
(after! man
  (require 'ansi-osc)

  (defadvice! +man--apply-osc8-a ()
    "Turn groff OSC 8 hyperlinks into buttons; drop the raw escape sequences."
    :after #'Man-fontify-manpage
    (let ((ansi-osc-handlers '(("8" . ansi-osc-hyperlink-handler))))
      (ansi-osc-apply-on-region (point-min) (point-max))))

  (defadvice! +man--strip-osc8-a (&rest _)
    "Strip leftover OSC sequences when not fontifying man pages."
    :after #'Man-cleanup-manpage
    (ansi-osc-filter-region (point-min) (point-max))))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
