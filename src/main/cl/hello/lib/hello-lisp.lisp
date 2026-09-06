(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(ql:quickload "uuid" :silent t)

(defconstant +min-exit-code+ 0)
(defconstant +max-exit-code+ 255)
(defconstant +invalid-exit-code+ 1)

(defun parse-exit-code (arguments)
  "Takes the command line arguments and returns the exit code to use.

Returns 0 when no argument was given. Returns 1 when the argument is not an
integer, or falls outside the 0..255 range a POSIX shell can report."
  (if (null arguments)
      +min-exit-code+
      (handler-case
          (let ((value (parse-integer (first arguments))))
            (if (<= +min-exit-code+ value +max-exit-code+)
                value
                +invalid-exit-code+))
        (parse-error () +invalid-exit-code+))))

(defun print-exit-code (exit-code)
  "Prints the exit code when it is non-zero and stays silent otherwise.
Returns the code unchanged so it can be passed onwards."
  (unless (= exit-code +min-exit-code+)
    (format t "Exiting with code ~a.~%" exit-code))
  exit-code)

(format t "Hello, world from ~a as UUID: ~a!~%"
        (string-right-trim "/" (namestring (uiop:getcwd)))
        (string-downcase (princ-to-string (uuid:make-v4-uuid))))

(uiop:quit
 (print-exit-code
  (parse-exit-code (uiop:command-line-arguments))))
