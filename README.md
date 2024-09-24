# ar-dir

An utility when creating new directories

‘M-x ar-dir-create RET ’

does the following:

- Create a new directory
- Prompt for a mnemonic name
- Create a command of this name, which will open a respective dired-buffer
- Create a shell-command of this name, which will point the shell into this directory
- Create a command for opening an note-file org-mode in this new created dir
  name this command like the dired-command followed by a "b"

# Install

ar-dir-storage.el holds the data, thus shipping an empty file here

First make a copy of your own

cp ar-dir-storage-default.el ar-dir-storage.el

Put this into Emacs init file:

(add-to-list 'load-path "/PATH/TO/ar-dir")

(require 'ar-dir)

(require 'ar-dir-storage)

(ar-create-path-funcs ar-pfad)

(ar-create-note-funcs ar-pfad))

