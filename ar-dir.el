;;; ar-dir.el --- key-directory pairs for convenient switch  -*- lexical-binding: t; -*-

;; Author: Andreas Röhler <andreas.roehler@online.de>, Tobias
;; Keywords: convenience

;; Version: 0.1

;; URL: https://github.com/andreas-roehler/ar-dir

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary: This uses an answer from Tobias
;;  ‘https://emacs.stackexchange.com/users/2370/tobias’ at
;; https://emacs.stackexchange.com/questions/37739/how-to-define-a-bundle-of-variable-and-function-pairs

;;; Code:

;; (require 'ar-dir-storage)

(defvar ar-pfad nil
  "Internal use only.")

(when (file-readable-p "ar-dir-storage.el")
  (load "ar-dir-storage.el" nil t)
  (ar-create-path-funcs ar-pfad)
  (ar-create-note-funcs ar-pfad)
  )

(defvar ar-debug-p nil
  "Assist debugging by switching to current buffer occasionally.")

(defcustom ar-dir-name "~/werkstatt/ar-dir"
  "Location of this file."
  :type 'string
  :group 'convenience)

(defcustom ar-dir-bin-directory "~/bin"
  "The directory, were the ‘cd’ shell-commands are stored.

Make sure, it is in $PATH"
  :type 'string
  :group 'convenience)

(defcustom ar-dir-storage "~/ar-dir-storage-default.el"
  "The file, were the switch-dir commands are stored."
  :type 'string
  :type 'string)

(defcustom note-file-name "ar-dir-note.org"
  "A file for taking notes to create in every new directory."
  :type 'string
  :type 'string)

(defcustom ar-dir-path-separator-char (if (memq system-type '(ms-dos windows-nt cygwin))
                                   "\""
                                 "/")
  "A string specifiyng the systems path-separator-char.")

(defun ar-neuname--intern (verzeichnis)
  (with-temp-buffer
    (when ar-debug-p (switch-to-buffer (current-buffer)))
    (insert verzeichnis)
    (let (erg)
      (while (not (bobp))
	(forward-word -1)
	(setq erg (concat (downcase (char-to-string (char-after))) erg)))
      erg)))

(defun ar-write-shell-jump (symbol pfad)
  (let ((pfad (replace-regexp-in-string "^/[^/]+/[^/]+/" "$HOME/" (expand-file-name pfad))))
    ;; (pfad (concat "$HOME" (substring pfad 1))))
    (with-temp-buffer
      (when ar-debug-p (switch-to-buffer (current-buffer)))
      (insert (concat "#!/bin/bash

# ---" (symbol-name symbol) "

if [ ! -d \"" pfad "\" ]\; then
echo \"Make Directory: " pfad "!\"
mkdir -pv " pfad "
fi

cd \"" pfad "\"

if [ $PWD == \"" pfad "\" ]\; then
:
else
cd \"" pfad "\"
fi

echo $PWD"))
      (if (file-readable-p (concat ar-dir-bin-directory ar-dir-path-separator-char (symbol-name symbol)))
	  (when (y-or-n-p (concat "Overwrite?: " (concat ar-dir-bin-directory ar-dir-path-separator-char (symbol-name symbol))))
	    (write-file (concat ar-dir-bin-directory ar-dir-path-separator-char (symbol-name symbol))))
	(write-file (concat ar-dir-bin-directory ar-dir-path-separator-char (symbol-name symbol))))
      (set-file-modes (concat ar-dir-bin-directory ar-dir-path-separator-char (symbol-name symbol)) (string-to-number "700" 8)))))

(defvar ar-write-shell-jump-p t)
(defun ar-toggle-ar-write-shell-jump-p ()
  (interactive)
  (setq ar-write-shell-jump-p (not ar-write-shell-jump-p)))

(defalias 'aup 'ar-update-pfad)
(defun ar-update-pfad ()
  (interactive)
  (with-current-buffer
      (find-file-noselect (expand-file-name ar-dir-storage))
    (let ((oldbuf (current-buffer)))
      (when ar-debug-p (switch-to-buffer (current-buffer)))
      (goto-char (point-min))
      (when (search-forward "(defvar ar-pfad" nil t)
        (beginning-of-line)
        (forward-sexp)
        (forward-line 1))
      (unless
          (looking-at "^[ \t\r]*$")
        (newline 2))
      (when
	  (search-forward "(setq ar-pfad" nil t)
        (beginning-of-line)
        (save-excursion
          (delete-region (point) (progn (search-forward "(provide" nil 'move) (line-beginning-position)))))
      (beginning-of-line)
      (split-line 1)
      (insert (concat "(setq ar-pfad \n" (make-string 2 32) "'(\n)"))
      (forward-line -1)
      (indent-according-to-mode)
      (end-of-line)
      (newline 1)
      (indent-according-to-mode)
      (when ar-pfad
        (dolist (ele ar-pfad)
          (insert (concat (prin1-to-string ele) "\n" (make-string 4 32)))
          (indent-according-to-mode)))
      ;; (newline-and-indent)
      (insert ")")
      (write-file (expand-file-name ar-dir-storage))
      (kill-buffer oldbuf))))

(defun ar-create-path-funcs (&optional pfadliste)
  (interactive)
  (let ((pfadliste (or pfadliste ar-pfad)))
    (mapc
     (lambda (x)
       (let* ((s (car x))
	      (p (concat (cdr x)))
	      (sym-p (intern
		      (symbol-name s)))
	      (sym-f (intern
		      (symbol-name s))))
	 (progn
	   (set sym-p p)
	   (fset sym-f `(lambda () (interactive) (dired ,sym-p)(goto-char (point-max))(skip-chars-backward " \t\r\n\f"))))
         ))
     pfadliste)))

(defun ar-create-note-funcs (&optional pfadliste)
  (interactive)
  (let ((pfadliste (or pfadliste ar-pfad)))
    (mapc
     (lambda (x)
       (let* ((s (car (read-from-string (concat (format "%s" (car x)) "b"))))
	      (p (concat (cdr x)))
	      (sym-p s
               ;; (intern
	       ;;        (symbol-name s))
               )
	      (sym-f s
               ;; (intern
	       ;;        (symbol-name s))

               ))
	 (progn
	   (set sym-p p)
	   (fset sym-f `(lambda () (interactive) (find-file (concat (format "%s" ,sym-p) "/befehle.org"))(goto-char (point-max))(skip-chars-backward " \t\r\n\f"))))
         ))
     pfadliste)))

(defun neu-befehle-org (name verzeichnis)
  "New file according to ‘note-file-name’, should it not exist."
  (unless (file-readable-p (concat verzeichnis "/" note-file-name))
    (with-current-buffer
	(find-file (concat verzeichnis "/" note-file-name))
      (write-file (concat verzeichnis "/" note-file-name)))))

(defalias 'dnvz 'ar-neuverzeichnis-delete-dir)
(defun ar-neuverzeichnis-delete-dir ()
  "Delete the directory from ‘ar-pfad’, ‘ar-dir-bin-directory’ ‘ar-dir-name’."
  (interactive)
  (let* ((name (read-from-minibuffer "Directory:: "))
	 (verzeichnis (concat default-directory name))
	 erg
	 (listelt (progn
		    (dolist (ele ar-pfad)
		      (when (equal (prin1-to-string (car ele)) name)
			(setq erg ele)))
		  erg)))
    (setq ar-pfad (remove listelt ar-pfad))
    (ar-update-pfad)
    (delete-directory verzeichnis t)
    (delete-file (concat ar-dir-bin-directory ar-dir-path-separator-char name))))

(defalias 'nvz 'ar-dir-create)
(defun ar-dir-create ()
  (interactive)
  (let* (
	 (verzeichnis (concat default-directory (read-from-minibuffer "Directory: ")))
	 (neuname (ar-neuname--intern (substring verzeichnis (1+ (string-match "/[^//]+$" verzeichnis)))))
	 (name-raw (read-from-minibuffer "Aufruf: " neuname))
	 (name (intern name-raw)))
    (unless (file-readable-p verzeichnis)
      (make-directory (substring verzeichnis (1+ (string-match "/[^//]+$" verzeichnis))) t))
    ;; (neu-befehle-org name-raw verzeichnis)
    (ar-write-shell-jump name verzeichnis)
    (when ar-pfad (setq ar-pfad (delete-dups ar-pfad)))
    (when  (map-contains-key ar-pfad name)
      (when (y-or-n-p (concat "Replace " (prin1-to-string name)))
	(setq ar-pfad (map-delete ar-pfad name))))
    (unless (map-contains-key ar-pfad verzeichnis)
      (push (cons name verzeichnis) ar-pfad)
      (ar-create-path-funcs (list (cons name verzeichnis)))
      (ar-create-note-funcs (list (cons name verzeichnis)))
      (ar-update-pfad)
      )))

(provide 'ar-dir)
;;; ar-dir.el ends here
