;;; Initializing package.el
(require 'package)
(setq package-enable-at-startup nil)

(setq package-archives '(("ELPA"  . "http://tromey.com/elpa/")
			 ("gnu"   . "http://elpa.gnu.org/packages/")
			 ("melpa" . "https://melpa.org/packages/")
			 ("org"   . "https://orgmode.org/elpa/")))
(package-initialize)

;;; Installing use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;;; The actual config file
;;;(when (file-readable-p "~/.emacs.d/config.org")
;;;  (org-babel-load-file (expand-file-name "config.org" "~/.emacs.d/")))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(hydra which-key general goto-chg evil-collection vterm evil zenburn-theme dracula-theme exwm xelb use-package async)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;;; Minor settings
(setq make-backup-files nil)
(setq auto-save-default nil)

(defalias 'yes-or-no-p 'y-or-n-p)

(use-package async
  :ensure t
  :init (dired-async-mode 1))

(setq load-prefer-newer t)

;;; which-key
(use-package which-key
  :ensure t
  :config
  (which-key-mode))

;;; Evil and evil-collection
(use-package evil
  :ensure t
  :init
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init))

;;; Window management keybindings
(global-set-key (kbd "s-h")  'windmove-left)
(global-set-key (kbd "s-l") 'windmove-right)
(global-set-key (kbd "s-k")    'windmove-up)
(global-set-key (kbd "s-j")  'windmove-down)

;;; leader key keybindings
(use-package general
  :ensure t
  :config
  ;;;(setq general-describe-keybinding-sort-function #'general-sort-by-car)
  ;;;(general-auto-unbind-keys)
  (general-def '(normal visual insert emacs)
    :prefix "SPC"
    :non-normal-prefix "M-SPC"
    "x" 'vterm
    "TAB" '(hydra-zoom/body :which-key "workspace")
    "b" '(:ignore t :which-key "buffer")
    "f" '(hydra-file/body :which-key "file")
    "r" '(:ignore t :which-key "run") 
    "p" '(:ignore t :which-key "project")
    "t" '(:ignore t :which-key "toggle")
    "w" '(:ignore t :which-key "window")
    ))

(use-package hydra
  :ensure t
  :config
  (defhydra hydra-zoom ()
  "zoom"
  ("g" text-scale-increase "in")
  ("l" text-scale-decrease "out"))

  (defhydra hydra-file ()
    "file"
    ("." find-file "find file")))

;;; Theme
(use-package zenburn-theme
  :ensure t
  :init
    (load-theme 'zenburn t))

;;; EXWM
(use-package exwm
	     :ensure t
	     :config

	     (require 'exwm-config)
	     (exwm-config-default))

;;; Setting simulation keys
(exwm-input-set-simulation-keys
 '(
   ;; movement
   ([?\C-b] . left)
   ([?\M-b] . C-left)
   ([?\C-f] . right)
   ([?\M-f] . C-right)
   ([?\C-p] . up)
   ([?\C-n] . down)
   ([?\C-a] . home)
   ([?\C-e] . end)
   ([?\M-v] . prior)
   ([?\C-v] . next)
   ([?\C-d] . delete)
   ([?\C-k] . (S-end delete))
   ;; cut/paste
   ([?\C-w] . ?\C-x)
   ([?\M-w] . ?\C-c)
   ([?\C-y] . ?\C-v)
   ;; search
   ([?\C-s] . ?\C-f)))

;;; Controlling audio
(defconst volumeModifier "4")

(defun audio/mute ()
  (interactive)
  (start-process "audio-mute" nil "amixer" "sset" "Master" "toggle"))

(defun audio/raise-volume ()
  (interactive)
  (start-process "raise-volume" nil "amixer" "sset" "Master" (concat volumeModifier "%+")))

(defun audio/lower-volume ()
  (interactive)
  (start-process "lower-volume" nil "amixer" "sset" "Master" (concat volumeModifier "%-")))

(dolist (k '(XF86AudioLowerVolume
	   XF86AudioRaiseVolume
	   XF86PowerOff
	   XF86AudioMute
	   XF86AudioPlay
	   XF86AudioStop
	   XF86AudioPrev
	   XF86AudioNext
	   XF86ScreenSaver
	   XF68Back
	   XF86Forward
	   Scroll_Lock
	   print))
(cl-pushnew k exwm-input-prefix-keys))

(global-set-key (kbd "<XF86AudioMute>") 'audio/mute)
(global-set-key (kbd "<XF86AudioRaiseVolume>") 'audio/raise-volume)
(global-set-key (kbd "<XF86AudioLowerVolume>") 'audio/lower-volume)

;;; Vterm (terminal emulator)
(use-package vterm
  :ensure t
  :init
    (setq vterm-always-compile-module t)
    (defun run-in-vterm-kill (process event)
  "A process sentinel. Kills PROCESS's buffer if it is live."
  (let ((b (process-buffer process)))
    (and (buffer-live-p b)
         (kill-buffer b))))

(defun run-in-vterm (command)
  "Execute string COMMAND in a new vterm.

Interactively, prompt for COMMAND with the current buffer's file
name supplied. When called from Dired, supply the name of the
file at point.

Like `async-shell-command`, but run in a vterm for full terminal features.

The new vterm buffer is named in the form `*foo bar.baz*`, the
command and its arguments in earmuffs.

When the command terminates, the shell remains open, but when the
shell exits, the buffer is killed."
  (interactive
   (list
    (let* ((f (cond (buffer-file-name)
                    ((eq major-mode 'dired-mode)
                     (dired-get-filename nil t))))
           (filename (concat " " (shell-quote-argument (and f (file-relative-name f))))))
      (read-shell-command "Terminal command: "
                          (cons filename 0)
                          (cons 'shell-command-history 1)
                          (list filename)))))
  (with-current-buffer (vterm (concat "*" command "*"))
    (set-process-sentinel vterm--process #'run-in-vterm-kill)
    (vterm-send-string command)
    (vterm-send-return)))
)
