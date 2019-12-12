# Changes in Emacs MMA mode

## 2019-12-30

* Add variable `mma-file-encoding` (default: `latin-1`) to force MMA
  buffers into Latin-1 encoding. This is required otherwise MMA will
  barf.

## 2018-12-29 (latest legacy release)

* Add support for xplayer MIDI player and make this player default.

* Add `//` comment syntax for use with `comment-dwim` and
  `comment-region`.
  
## 2014-02-08 (initial release)

* Emacs-23.4.1 version.

* This version will run mma to update the actual keywords to highlight.
  **It will not work without the mma program.**

