# Changes in Emacs MMA mode

## 2019-12-12

* Add preview function (bound to C-c C-v).

  This function looks for a sentinel `// End of Preamble` in the
  current buffer. If found, everything from the start of the buffer up to and
  including this line will be written to a temp file.
  
  The content of the current selection is appended to the file and
  then an mma compile will process this file and play it. This makes
  it easy to quickly play selected portions of the MMA song in
  progress.

* Small cosmetic changes and typo fixes.

## 2018-12-30

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

