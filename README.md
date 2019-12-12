# mma.el

## Emacs major mode for mma: Musical MIDI Accompaniment

This is a majore mode to edit and play MMA files.

It is based on an original version from Vu Ngoc San.

Enhancements:

* Force MMA files to be encoded in Latin1, MMA cannot handle Unicode yet.

The MMA program is written by Bob van der Poel.
See [his MMA site](https://www.mellowwood.ca/mma) for
details on the MMA program.

## Original version and disclaimer:

(C) 2005-2014 VU NGOC San

This is written for Emacs-23 and should work for emacs-22. No
guarantee for older emacsen.

By the way, this mode is pretty minimalistic. I just wrote the
features I needed. Any suggestion for improvement is welcome.

## Installation

Copy the file `lisp/mma.el` to a place where it can be found by Emacs
(a place that is in Emacs' `load-path`).

In your `.emacs` add the following lines:

    (autoload 'mma-mode "mma" "mma music file mode" t)
    (add-to-list 'auto-mode-alist
                 '("\\.mma$" . mma-mode))

Then when you open a `.mma` file you should have a `Mma` menu in the menu-bar.
It shows the keyboard shortcuts as well.

## MIDI players

This mode is originally written for using the midi player `xplayer`, `aplaymidi`
or the `timidity` midi synthesizer. Other programms can be used via
the Mma menu.

You can set your default midi player in your `.emacs`, for instance, add:

    (setq mma-midi-player "/usr/bin/aplaymidi")
    (setq mma-midi-player-arg "-p 128:0")

An alternate midi player:

	(setq mma-midi-player "/usr/bin/playmidi")
	(setq mma-midi-player-arg "-e -D /dev/midi")
;;

## License

You are free to do whatever you want with this file as long as you
include credits to the original author.

## Hints

### Use `aplaymidi` to get the list of midi ports

    aplaymidi -l

or:

    aplaymidi -l | sed -ne 's/^\([0-9]*:[0-9]*\).*$/\1/p'
