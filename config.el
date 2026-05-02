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

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'gruvbox-dark-hard)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; C/C++ indentation settings
(setq c-basic-offset 4)
(setq c-ts-mode-indent-offset 4)
(setq c++-ts-mode-indent-offset 4)

;; Fix project root detection for C/C++ projects
;; Doom uses Projectile for project detection, which checks certain files
;; to determine project roots. By default it finds .git in parent directories
;; before checking for project-specific files like CMakeLists.txt.
;; We add these to projectile-project-root-files-bottom-up so they're
;; checked BEFORE .git, ensuring subdirectory projects are recognized.
(after! projectile
  ;; Add to bottom-up list so these are checked before .git
  (add-to-list 'projectile-project-root-files-bottom-up ".clangd")
  (add-to-list 'projectile-project-root-files-bottom-up "CMakeLists.txt")
  (add-to-list 'projectile-project-root-files-bottom-up "compile_commands.json")
  (add-to-list 'projectile-project-root-files-bottom-up ".project"))

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
;;
;; Configure eglot to use ty as the LSP server
;; Note: Must specify :language-id "python" because ty expects "python" but
;; python-base-mode would send "python-base" which ty doesn't recognize,
;; resulting in no type checking diagnostics being shown.
;; See: https://github.com/astral-sh/ty/issues/2937
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((python-base-mode :language-id "python") . ("ty" "server")))
  ;; Disable inlay hints globally for all Eglot managed buffers
  (add-to-list 'eglot-ignored-server-capabilities :inlayHintProvider))

;; Use ruff for formatting via Apheleia
(with-eval-after-load 'apheleia
  (setf (alist-get 'python-mode apheleia-mode-alist)
        '(ruff-isort ruff))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist)
        '(ruff-isort ruff)))

;; Limit eldoc to single line (truncate long function signatures)
(setq eldoc-echo-area-use-multiline-p nil)

;; Font
;; (setq doom-font (font-spec :size 16))
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 16 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font" :size 16)
      doom-big-font (font-spec :family "JetBrainsMono Nerd Font" :size 24))

;; Enable copy, pasting, and in-line viewing snippets
(use-package! org-download
  :after org
  :config
  (defun my/set-org-download-dir ()
    (when (buffer-file-name)
      (setq-local org-download-image-dir
                  (expand-file-name
                   "images"
                   (file-name-sans-extension (buffer-file-name))))))

  (add-hook 'org-mode-hook #'my/set-org-download-dir)

  (setq org-download-method             'directory
        org-download-heading-lvl         nil)
  ;; org-download-screenshot-method  "flameshot gui --raw > %s")

  (map! :map org-mode-map
        :localleader
        "P" #'org-download-clipboard))
