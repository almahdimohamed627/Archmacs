;; Basic Emacs configuration for Archmacs
;; This configuration sets up EXWM and basic development tools

;; Set up package management
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives
             '("gnu" . "https://elpa.gnu.org/packages/") t)

(package-initialize)

;; Install use-package if not present
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; Basic settings
(setq inhibit-startup-screen t)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; Theme setup
(use-package dracula-theme
  :config
  (load-theme 'dracula t))

;; EXWM configuration
(use-package exwm
  :config
  (require 'exwm-config)
  (exwm-config-example)
  
  ;; Set default key bindings
  (setq exwm-input-global-keys
        `(([?\s-r] . exwm-reset)
          ([?\s-w] . exwm-workspace-switch)
          ([?\s-&] . (lambda (command)
                       (interactive (list (read-shell-command "$ ")))
                       (start-process-shell-command command nil command)))
          ;; Move between windows
          ([?\s-h] . windmove-left)
          ([?\s-j] . windmove-down)
          ([?\s-k] . windmove-up)
          ([?\s-l] . windmove-right)
          ;; Switch to workspace
          ,@(mapcar (lambda (i)
                      `(,(kbd (format "s-%d" i)) .
                        (lambda ()
                          (interactive)
                          (exwm-workspace-switch-create ,i))))
                    (number-sequence 0 9))))
  
  ;; Set up EXWM to use Super key as prefix
  (setq exwm-input-prefix-keys
        '("\C-x" "\C-u" "\C-h" "\M-x" "\M-`" "s-"))

  ;; Enable EXWM
  (exwm-enable))

;; Enable which-key for discovering keybindings
(use-package which-key
  :config
  (which-key-mode))

;; Enable Ivy and Counsel
(use-package ivy
  :config
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t)
  (setq enable-recursive-minibuffers t))

(use-package counsel
  :config
  (counsel-mode 1))

;; Better completion
(use-package swiper
  :bind ("C-s" . swiper))

;; Magit for Git
(use-package magit
  :bind ("C-x g" . magit-status))

;; Org mode settings
(use-package org
  :config
  (setq org-startup-indented t)
  (setq org-src-fontify-natively t))

;; Development tools
(use-package projectile
  :config
  (projectile-mode +1)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

;; Display battery status in mode line
(display-battery-mode 1)

;; Display time in mode line
(display-time-mode 1)

;; Custom modeline
(setq-default mode-line-format
  (list
   '(:eval (propertize " %b " 'face 'font-lock-keyword-face))
   '(:eval (propertize " %p" 'face 'font-lock-comment-face))
   " %m"
   '(:eval (propertize (format-time-string " %H:%M ") 'face 'font-lock-string-face))))

;; Auto-save and backup settings
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)))

;; Server for emacsclient
(server-start)

;; Message at startup
(message "Archmacs Emacs configuration loaded successfully!")
