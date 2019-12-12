;; mma.el, emacs major mode for mma: Musical MIDI Accompaniment
;;
;; Copyright VU NGOC San 2005-2014
;; san.vu-ngoc_ _@_ _univ-rennes1.fr
;; 
;; version February 8, 2014: emacs-23.4.1 version.  This version will
;; automatically update the keywords to highlight with your version of
;; mma.
;;
;; this is written for emacs-23 and should work for emacs-22. No
;; guarantee for older emacsen.  By the way, this mode is pretty
;; minimalistic. I just wrote the features I needed. Any suggestion
;; for improvement is welcome.
;;
;; mma's author is Bob van der Poel
;; mma can be obtained from http://www.mellowood.ca/mma/
;; *******************************************************************
;; In order to automatically load mma-mode for .mma files, adapt (path)
;; and put the following in your .emacs file: 
;; *******************************************************************
;;   ;this is where I store the file mma.el
;;   (setq load-path (cons "/my/elisp/path/" load-path))
;;   (autoload 'mma-mode "mma" "mma music file mode" t)
;;   (setq auto-mode-alist
;;       (append '(("\\.mma$" . mma-mode)) 
;;	       auto-mode-alist))
;; *******************************************************************
;; Then if you open a .mma file you should have a Mma menu in the menu-bar.
;; It shows the keyboard shortcuts as well.
;;
;; *******************************************************************
;; You can set your default midi player in your .emacs
;; for instance, add:
;; (setq mma-midi-player "/usr/bin/aplaymidi")
;; (setq mma-midi-player-arg "-p 128:0")
;; *******************************************************************
;;
;; you are free to do whatever you want with this file as long as you
;; include this header.
;; 
;; *******************************************************************
;;
;; using aplaymidi to get the list of midi ports:
;; aplaymidi -l
;; or:
;; aplaymidi -l | sed -ne 's/^\([0-9]*:[0-9]*\).*$/\1/p'
;;
;; This mode is written for using the midi player aplaymidi
;; or the timidity midi synthetiser. Other programms can be
;; used via the Mma menu.
;;
;; an alternate midi player:
;; playmidi -e -D /dev/midi file.mid 
;;
;; *******************************************************************

;(require 'font-lock)
(require 'compile)
(setq compilation-error-regexp-alist
      (cons '(".*ERROR:<Line \\([0-9]+\\)><File:\\(.+\\)>" 2 1)
	    compilation-error-regexp-alist)
)

(setq compilation-finish-function nil)

;(setq shell-file-name "bash")

(defvar mma-command "mma"
  "full command line for executing mma")

(defvar mma-midi-player 
;"/usr/bin/kmid"
"/usr/bin/timidity"
;"/usr/bin/aplaymidi"
  "program for playing a midi file")

(defvar mma-midi-player-arg
"-Os"
;"-p 128:0"
  "arguments to give to mma-midi-player"
)

(defvar mma-timidity-default-options "-Os"
  "default options for timidity"
)

(defvar mma-midi-port "128:0"
"MIDI port used by mma"
)

(defvar mma-file-encoding 'latin-1)

(defvar mma-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-c" 'mma-compile)
    (define-key map "\C-c\C-t" 'mma-test)
    (define-key map "\C-c\C-p" 'mma-play)
    (define-key map "\C-c\C-x" 'mma-stop)
    (define-key map "\C-c\C-r" 'mma-compile-and-play)
    map)
  "Keymap used in mma-mode."
  )

(defun mma-mode ()
  "Major mode for mma"
  (interactive)
  (kill-all-local-variables)
  (use-local-map mma-mode-map)
  (setq major-mode 'mma-mode)
  (setq buffer-file-coding-system mma-file-encoding)
  (setq mode-name "Mma")
  (setq comment-start "// ")
  (setq comment-end "")
  (setq comment-column 32)
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(mma-font-lock-keywords t t))
  )

(defun mma-midi-name ()
  "parse the compilation buffer to extract the midi file name. If not found, or if no such buffer, returns the .mma file with .mid extension"
  (save-excursion  
    (if (get-buffer "*mma-compilation-buffer*")
	(progn
	  (set-buffer "*mma-compilation-buffer*")
	  (goto-char 0)
	  (re-search-forward "'\\([^']*\.mid\\)'")
					;ou mettre tout le nom de fichier
	  (let ((mma-out-dir (match-string 1)))
	    (if mma-out-dir 
		mma-out-dir 
	      (concat (file-name-sans-extension buffer-file-name) 
		      ".mid"))
	    ))
      (concat (file-name-sans-extension buffer-file-name) 
	      ".mid")
      )
    )
  )

(defun mma-compilation-buffer-name (foo)
  "mma-compilation-buffer"
  "*mma-compilation-buffer*"
  )

(defun mma-compile-internal-args (arg)
  "save current buffer and run mma on it with arguments (allowing auto playing afterwards)"
; using relative file names because of mma's limitations when setoutdir is used
  (save-excursion (save-buffer))
  (compilation-start
   (concat mma-command (concat " " arg) (file-relative-name buffer-file-name)
					;" -f" mma-out-file
	   )
   nil 'mma-compilation-buffer-name nil)
  )

(defun mma-compile-internal ()
  "save current buffer and run mma on it (allowing auto playing afterwards)"
  (mma-compile-internal-args "")
  )

(defun mma-compile ()
 "save current buffer and run mma on it (disabling auto-playing)"
  (interactive)
  (setq compilation-finish-function nil)
  (mma-compile-internal)
)

(defun mma-test ()
  "save current buffer, run mma on it without generating midi file"
  (interactive)
  (mma-compile-internal-args "-sn ")
  )


(defun mma-play ()
  "play already generated midi file in the *last* compilation"
  (interactive)
  (if (and (buffer-modified-p)
	   (y-or-n-p (concat "Buffer " (buffer-name) 
			     " has been modified. Save and compile now ?")))
      (save-excursion
	(save-buffer)
	(mma-compile-and-play))
    (mma-play-internal nil nil)
    )
  )

(defun mma-play-internal (buf arg)
  "play midi file.  
This function can be called automatically by the compile mode. 
Args are disregarded"
  (start-process-shell-command 
   "playing midi" "midi buffer" 
   (concat (shell-quote-argument mma-midi-player) " "
	   mma-midi-player-arg)
   (shell-quote-argument (mma-midi-name)))
  (display-buffer "midi buffer")  
  )


(defun mma-stop ()
  "kill midi process"
  (interactive)
  (delete-process "midi buffer") 
  (display-buffer "midi buffer")
  )

(defun mma-compile-and-play ()
  "save current buffer, run mma on it and play generated midi file"
  (interactive)
  (setq compilation-finish-function 'mma-play-internal)
  (mma-compile-internal)
  )


(defun mma-select-midi-port ()
  "ask user for midi port"
  (setq mma-midi-port (read-string 
		       (concat "Enter MIDI port (default " mma-midi-port "): ")
		       "" nil mma-midi-port))
  )

(defun mma-select-options ()
  "ask user for options for the midi player"
  (setq mma-midi-player-arg 
	(read-string 
	 (concat "Enter further options for " mma-midi-player " : ")
	 (concat mma-midi-player-arg " ") nil)) 
  )

(defun mma-select-audio ()
  "ask user for the way of playing midi files.\n Can be aplaymidi, timidity or other" 
  (interactive)
  (mma-set-midi (read-string
		 "Enter MIDI program (aplaymidi,timidity or other): "
		 ""))
  )

(defun mma-set-midi ( synth )
  "sets up MIDI playing according to synth, which can be:\n
   aplaymidi,timidity,other"
  (cond ((string= synth "aplaymidi") 
	 (progn 
	   (setq mma-midi-player "aplaymidi")
	   (setq mma-midi-player-arg (concat"-p " (mma-select-midi-port)))))
	((string= synth "timidity")
	 (progn
	   (setq mma-midi-player "timidity")
	   (setq mma-midi-player-arg mma-timidity-default-options)))
	(t
	 (progn
	   (setq mma-midi-player 
		 (read-string
		  "Enter command name for playing midi (without options) (eg. kmid): "
		  ""))
	   (setq mma-midi-player-arg "")))
	)
  (mma-select-options)
  )


(defvar menu-bar-mma-menu (make-sparse-keymap "Mma"))
(define-key mma-mode-map [menu-bar mma] (cons "Mma" menu-bar-mma-menu))

(define-key menu-bar-mma-menu [mma-audio]
  '("MIDI settings" . mma-select-audio))
(define-key menu-bar-mma-menu [mma-sep2]
  '("--"))
(define-key menu-bar-mma-menu [mma-error]
  '("Show compilation error" . next-error))
(define-key menu-bar-mma-menu [mma-sep1]
  '("--"))
(define-key menu-bar-mma-menu [mma-test]
  '("Verify buffer" . mma-test))
(define-key menu-bar-mma-menu [mma-stop]
  '("Stop MIDI" . mma-stop))
(define-key menu-bar-mma-menu [mma-play]
  '("Play MIDI file" . mma-play))
(define-key menu-bar-mma-menu [mma-compile]
  '("Create MIDI file" . mma-compile))
(define-key menu-bar-mma-menu [mma-compile-and-play]
  '("Compile and play" . mma-compile-and-play))

(defvar mma-track-commands 
  '("Accent" "Articulate" "ChShare" "Channel" "ChannelPref"
    "Compress" "Copy" "Debug" "Define"
    "Delete" "Direction" "DrumType" "DupRoot" "ForceOut"
     "Harmony" "HarmonyOnly" "HarmonyVolume" "Invert" "Limit"
     "MIDIClear" "MIDIGliss" "MIDIInc" "MIDIPan" "MIDISeq" "MIDITName"
    "MIDIVoice" "MIDIVolume" "Mallet" "NoteSpan" "Octave" "Off" "On"
    "RSkip" "RTime" "RVolume" "Range"
    "Riff" "ScaleType" "Sequence" "Strum" "Tone" "Voice"
    "Voicing")
  "list of mma commands requiring a leading track specification" 
  )

(defvar mma-track-type
  '("Drum" "Chord" "Arpeggio" "Scale" "Bass" "Walk" "Solo" "Melody")
  "list of mma patterns and track descriptions"
  )

(defvar mma-commands 
  '("Cresc" "Cut" "Decresc" "SeqClear"
    "SeqRnd" "SeqRndWeight" "Unify" "Volume")
  "list of mma commands with an optional leading track specification"
  )

(defvar mma-non-track-commands 
  '("AdjustVolume" "AllTracks" "Author"
    "AutoSoloTracks" "BarNumbers" "BarRepeat" "BeatAdjust" 
    "Begin" "ChordAdjust"
    "Comment" "Debug" "Dec" "DefChord" "DefGroove" "Doc" "DrumTR"
    "DrumVolTr" "EndIf" "EndMset"
    "End" "EndIf" "EndMset" "EndRepeat" "Eof" "Fermata" 
    "Goto" "Groove" "If" "IfEnd" "Inc" "Include"
    "KeySig" "Label" "Lyric" "MIDI" "MidiFile" "MIDIMark" "MIDISplit"
    "MmaEnd" "MmaStart" "Mset" "MsetEnd"
     "Print" "PrintActive" "PrintChord" "Repeat" "RepeatEnd" "RepeatEnding"
     "RndSeed" "RndSet"
     "Seq" "SeqSize" "Set" "SetAutoLibPath" "SetIncPath" "SetLibPath"
     "SetOutPath"
     "ShowVars" "StackValue" "SwingMode" "Tempo"
     "Time" "TimeSig" "Transpose" "UnSet" "Use" "VExpand" "VoiceTr"
     "VoiceVolTr")
  "list of mma non-track commands"
  )

(defun mma-create-regexp (list)
 "creates a regexp from a list of strings"
  (interactive)
  (let ((value ""))
    (dolist (word list value)
      (setq value (concat value "\\|" word)))
    (store-substring value 1 "(")
    (concat value "\\)")
    )
  )


(defun mma-font-lock ()
  "sets variables for font-lock mode"
;; the case is not important in regexp
  (defvar mma-font-lock-keywords
    (let ((mma-commands-reg 
	   (concat  "^[ \t]*" (mma-create-regexp mma-commands) "[ \t\n]"))
	  (mma-track-type-reg 
	   (concat  "\\b" (mma-create-regexp mma-track-type) 
		    "\\(-[a-z]*[0-9]*\\|[ \t\n]\\)"))
	  (mma-inline-track-commands-reg 
	   (concat  "[ \t]*" "\\b" (mma-create-regexp mma-track-type) 
		    "\\(-[a-z]*[0-9]*[ \t]\\|[ \t]\\)" "[ \t]*"
		    (mma-create-regexp mma-track-commands) "[ \t]+.?"))
	  (mma-track-commands-reg 
	   (concat  "^[ \t]*" (mma-create-regexp mma-track-commands) "[ \t]+.?"))
	  (mma-non-track-commands-reg 
	   (concat  "^[ \t]*" (mma-create-regexp mma-non-track-commands) "\\b"))
	  )
      (list 
       (cons "//.*$"  font-lock-comment-face)
       (cons mma-track-type-reg font-lock-string-face)
       (cons mma-track-commands-reg 1)
       (cons mma-inline-track-commands-reg 3)
       (cons mma-commands-reg font-lock-keyword-face)
       (cons "^\\([0-9]+\\)[ \t\n]" '(1 font-lock-function-name-face))
       (cons mma-non-track-commands-reg font-lock-builtin-face)
       ))
    "Default expressions to highlight in Mma mode."
    )
  )

;; functions to parse "mma -Dk" output.

; Here we make a list out of a set of separate all-capitalised words in one line
(defun searchloop (list)
  (re-search-forward "\\([A-Z]+\\)\\( \\|$\\)")
  (let ((new (cons (match-string 1) list)))
    (if (or (= (point) (point-max))
	    (= 10 (char-after (point)))
	    )
	new
      (searchloop new)
      ))
  )
  
(defun get-mma-keywords (token)
  "parse the output of mma -Dk to extract mma keywords. 
Here we get the list corresponding to token"
  (save-excursion  
    (if (get-buffer "mma -Dk buffer")
	(progn
	  (set-buffer "mma -Dk buffer")
	  (goto-char 0)
	  (re-search-forward token)
	  ;(narrow-to-region (line-beginning-position) (line-end-position))
	  (searchloop nil)
	  ;(widen)
	  )
      )
    ))

; re-initialise keywords using mma -Dk, if possible
(call-process mma-command nil "mma -Dk buffer" nil "-Dk")
(let ((trackname (get-mma-keywords "Base track names: "))
      (commands (get-mma-keywords "Commands: "))
      (trackcommands (get-mma-keywords "TrackCommands: ")))
  (if trackname (setq mma-track-type trackname))
  (if commands (setq mma-non-track-commands commands))
  (if trackcommands (setq mma-track-commands trackcommands))
)
(kill-buffer "mma -Dk buffer")
(mma-font-lock)

(provide 'mma-mode)

;; end of file mma.el
