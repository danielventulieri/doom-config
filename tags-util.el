;;; ~/.doom.d/tags-util.el -*- lexical-binding: t; -*-
;;; https://github.com/Wilfred/.emacs.d/blob/a373d6849e1a3d8ba50a047a1e208274a656019e/user-lisp/tags-utils.el#L44
;;; tags-utils.el --- programmatically regenerate TAGS using etags

;; Author: Wilfred Hughes <me@wilfred.me.uk>
;; Created: 1 October 2012
;; Version: 0.1

;;; Commentary

;; Requires ack to be installed.

;; Code convention: tags/* are internal functions, tags-* are
;; top-level interactive commands.


(autoload 'vc-git-root "vc-git")

(defun tags-utils/shell-in-dir (command directory)
  "Behaves the same as `shell-command-to-string', but allows us
to specify the directory to run the command in.
Note that it's not sufficient to use absolute paths with
shell-command-to-string, since it assumes that the buffer's value
of `default-directory' is a path that exists. If not, it crashes."
  (let ((normalized-path (file-name-as-directory directory))
        (original-default-directory default-directory)
        (command-output))
    (when (not (file-exists-p normalized-path))
      (error "Directory %s doesn't exist" normalized-path))
    (setq default-directory normalized-path)
    (setq command-output (shell-command-to-string command))
    (setq default-directory original-default-directory)
    command-output))

(defun tags-utils/regenerate (file-path)
  (tags-utils/shell-in-dir "rm -f TAGS" file-path)
  (tags-utils/shell-in-dir "git ls-files -z | egrep \"(\.el|\.py)$\" -z | xargs --null etags -a" file-path))

;; todo: move to http://www.emacswiki.org/emacs/repository-root.el
(defun tags-utils/project-root (file-path)
  (unless file-path (error "This buffer isn't associated with a file"))
  (let ((git-repo-path (vc-git-root file-path)))
    (or git-repo-path (read-directory-name "Project root: " default-directory))))

(defun tags-generate-for-this-repo ()
  "Regenerate the TAGS file in the root of the current git
repository. This TAGS table is then added to the list of
tags tables searched by Emacs."
  (interactive)
  (let ((project-root (tags-utils/project-root default-directory)))
    (tags-utils/regenerate project-root)
    (add-to-list 'tags-table-list (concat project-root "TAGS"))))

(require 'etags-select)

(global-set-key (kbd "<f6>") 'etags-select-find-tag-at-point)
(global-set-key (kbd "M-.") 'etags-select-find-tag)
(global-set-key (kbd "M-,") 'pop-tag-mark)

(defadvice etags-select-find-tag (around case-sensitive-matching activate)
  (let ((ido-case-fold nil))
    ad-do-it))

(defun etags-select-find-tag-other-window ()
  "Equivalent to `etags-select-find-tag-at-point' but
opening another window so the call site is still visible."
  (interactive)
  (delete-other-windows)
  (split-window-right)
  (other-window 1)
  (etags-select-find-tag-at-point))

(global-set-key (kbd "C-c M-.") 'etags-select-find-tag-other-window)

;; finding tags should be case sensitive
(setq tags-case-fold-search nil)


(provide 'tags-utils)
