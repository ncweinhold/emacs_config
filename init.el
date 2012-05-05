(require 'package)
(add-to-list 'package-archives
	     '("marmalade" . "http://marmalade-repo.org/packages/") t)
(package-initialize)

(setq inhibit-startup-message t)
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))

(defun slime ()
  (interactive)
  (fmakunbound 'slime)
  (load (expand-file-name "~/quicklisp/slime-helper.el"))
  (set-language-environment "UTF-8")
  (setq slime-net-coding-system 'utf-8-unix)
  (setq inferior-lisp-program "/usr/local/bin/sbcl")
  (slime))

(defun turn-on-paredit ()
  (paredit-mode 1))

(defvar electrify-return-match
  "[\]}\)\"]"
  "If this regexp matches the text after the cursor, do an \"electric\" return.")

(defun electrify-return-if-match (arg)
  "If the text after the cursor matches `electrify-return-match' then open and indent an empty line between the cursor and the text. Move the cursor to the new line."
  (interactive "P")
  (let ((case-fold-search nil))
    (if (looking-at electrify-return-match)
        (save-excursion (newline-and-indent)))
    (newline arg)
    (indent-according-to-mode)))

(defun override-slime-repl-bindings-with-paredit ()
  (define-key slime-repl-mode-map
    (read-kbd-macro paredit-backward-delete-key) nil))

(autoload 'paredit-mode "paredit"
  "Minor mode for pseudo-structurally editing lisp code." t)

(add-hook 'emacs-lisp-mode-hook
	  (lambda ()
	    (paredit-mode t)
	    (turn-on-eldoc-mode)
	    (eldoc-add-command
	     'paredit-backward-delete
	     'paredit-close-round)
	    (local-set-key (kbd "RET") 'electrify-return-if-match)
	    (eldoc-add-command 'electrify-return-if-match)
	    (show-paren-mode t)))

(add-hook 'lisp-mode-hook
	  (lambda ()
	    (paredit-mode t)
	    (local-set-key (kbd "RET") 'electrify-return-if-match)
	    (show-paren-mode t)))

(add-hook 'lisp-interaction-mode-hook
	  (lambda ()
	    (paredit-mode +1)))

(add-hook 'slime-repl-mode-hook 
	  (lambda () 
	    (paredit-mode t)
	    (override-slime-repl-bindings-with-paredit)
	    (show-paren-mode t)))

(add-hook 'clojure-mode-hook 'turn-on-paredit)
(add-to-list 'auto-mode-alist '("\.cljs$" . clojure-mode))

(defun shell-send-input (input)
  "Send INPUT into the *shell* buffer and leave it visible."
  (save-selected-window
    (switch-to-buffer-other-window "*shell*")
    (goto-char (point-max))
    (insert input)
    (comint-send-input)))

(defun defun-at-point ()
  "Return the text of the defun at point."
  (apply #'buffer-substring-no-properties
         (region-for-defun-at-point)))

(defun region-for-defun-at-point ()
  "Return the start and end position of defun at point."
  (save-excursion
    (save-match-data
      (end-of-defun)
      (let ((end (point)))
        (beginning-of-defun)
        (list (point) end)))))

(defun expression-preceding-point ()
  "Return the expression preceding point as a string."
  (buffer-substring-no-properties
   (save-excursion (backward-sexp) (point))
   (point)))

(defun shell-eval-last-expression ()
  "Send the expression preceding point to the *shell* buffer."
  (interactive)
  (shell-send-input (expression-preceding-point)))

(defun shell-eval-defun ()
  "Send the current toplevel expression to the *shell* buffer."
  (interactive)
  (shell-send-input (defun-at-point)))

(add-hook 'clojure-mode-hook
          '(lambda ()
             (define-key clojure-mode-map (kbd "C-c e") 'shell-eval-last-expression)
             (define-key clojure-mode-map (kbd "C-c x") 'shell-eval-defun)))
