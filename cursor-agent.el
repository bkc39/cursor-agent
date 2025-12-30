;;; cursor-agent.el --- Run cursor-agent in vterm  -*- lexical-binding: t; -*-

;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (vterm "0.0"))
;; Keywords: tools, convenience
;; URL: https://github.com/yourname/cursor-agent

;;; Commentary:
;;
;; A small wrapper that launches the `cursor-agent` executable inside a vterm
;; buffer, intended for installation via `use-package' with `:vc'.
;;
;; Public entry points:
;; - `cursor-agent'          Start (or switch to) a cursor-agent vterm.
;; - `cursor-agent-restart'  Restart cursor-agent vterm.
;; - `cursor-agent-run'      Start with prompted extra args.
;;
;;; Code:

(require 'cl-lib)

(defvar vterm--process)
(declare-function vterm "vterm" (&optional buffer-name))
(declare-function vterm-send-string "vterm" (string &optional paste-p))
(declare-function vterm-send-return "vterm" ())
(declare-function project-current "project" (&optional maybe-prompt dir))
(declare-function project-root "project" (project))

(defgroup cursor-agent nil
  "Run the cursor-agent CLI in vterm."
  :group 'tools
  :prefix "cursor-agent-")

(defcustom cursor-agent-executable "cursor-agent"
  "Path to the `cursor-agent` executable."
  :type 'string)

(defcustom cursor-agent-default-args nil
  "Default arguments passed to `cursor-agent-executable`."
  :type '(repeat string))

(defcustom cursor-agent-buffer-name "*cursor-agent*"
  "Base buffer name used for the cursor-agent vterm."
  :type 'string)

(defcustom cursor-agent-use-project-root t
  "When non-nil, use the current project root as `default-directory`."
  :type 'boolean)

(defcustom cursor-agent-per-project-buffer t
  "When non-nil, create a distinct buffer per project."
  :type 'boolean)

(defcustom cursor-agent-command-shell-quote t
  "When non-nil, shell-quote args before sending to vterm."
  :type 'boolean)

(defun cursor-agent--require-vterm ()
  (unless (require 'vterm nil t)
    (user-error "cursor-agent requires vterm; please install the `vterm` package")))

(defun cursor-agent--project-root ()
  (when (and cursor-agent-use-project-root (fboundp 'project-current))
    (when-let* ((project (project-current nil)))
      (expand-file-name (project-root project)))))

(defun cursor-agent--buffer-name (root)
  (if (and cursor-agent-per-project-buffer root)
      (format "%s<%s>"
              cursor-agent-buffer-name
              (file-name-nondirectory (directory-file-name root)))
    cursor-agent-buffer-name))

(defun cursor-agent--shell-command (args)
  (let ((all (cons cursor-agent-executable (append cursor-agent-default-args args))))
    (mapconcat
     #'identity
     (if cursor-agent-command-shell-quote
         (mapcar #'shell-quote-argument all)
       all)
     " ")))

(defun cursor-agent--vterm-live-p ()
  (and (boundp 'vterm--process)
       (processp vterm--process)
       (process-live-p vterm--process)))

(defun cursor-agent--vterm-send-command (buffer command)
  (let ((attempts 0)
        (max-attempts 40))
    (cl-labels
        ((try-send ()
           (if (not (buffer-live-p buffer))
               nil
             (with-current-buffer buffer
               (if (cursor-agent--vterm-live-p)
                   (progn
                     (goto-char (point-max))
                     (vterm-send-string command)
                     (vterm-send-return))
                 (cl-incf attempts)
                 (when (< attempts max-attempts)
                   (run-at-time 0.05 nil #'try-send)))))))
      (try-send))))

(defun cursor-agent--start (root args &optional restart)
  (cursor-agent--require-vterm)
  (let* ((default-directory (or root default-directory))
         (buffer-name (cursor-agent--buffer-name root))
         (existing (get-buffer buffer-name)))
    (when (and restart (buffer-live-p existing))
      (kill-buffer existing)
      (setq existing nil))
    (let ((buf (or existing (vterm buffer-name))))
      (pop-to-buffer buf)
      (unless existing
        (cursor-agent--vterm-send-command buf (cursor-agent--shell-command args)))
      buf)))

;;;###autoload
(defun cursor-agent (&optional restart)
  "Start (or switch to) a cursor-agent vterm buffer.

With prefix arg RESTART (\\[universal-argument]), kill any existing buffer and
start a new one."
  (interactive "P")
  (cursor-agent--start (cursor-agent--project-root) nil restart))

;;;###autoload
(defun cursor-agent-restart ()
  "Restart cursor-agent in vterm."
  (interactive)
  (cursor-agent t))

;;;###autoload
(defun cursor-agent-run (args &optional restart)
  "Start cursor-agent with prompted ARGS.

ARGS is read as a shell-like string and split with `split-string-and-unquote`.
With prefix arg RESTART (\\[universal-argument]), restart the buffer."
  (interactive
   (list (split-string-and-unquote
          (read-string "cursor-agent args: "))
         current-prefix-arg))
  (cursor-agent--start (cursor-agent--project-root) args restart))

(provide 'cursor-agent)
;;; cursor-agent.el ends here
