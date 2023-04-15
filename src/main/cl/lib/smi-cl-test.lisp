(write-line "Hello, world!")

#|
(defun kasutamine ()
  (format t "Kasutamine: minuprogramm [-h] [-n num] [-f float] [-s str]~%"))

(defun main (argv)
  (let ((optlist '("-h" "-n:" "-f:" "-s:"))
        (optargs (parse-opts argv)))
    (dolist (optarg optargs)
      (let ((opt (car optarg))
            (arg (cdr optarg)))
        (case opt
          ("-h" (kasutamine))
          ("-n" (let ((num (parse-integer arg)))
                  (format t "num = ~D~%" num)))
          ("-f" (let ((float (parse-float arg)))
                  (format t "float = ~F~%" float)))
          ("-s" (format t "str = ~A~%" arg))
          (t (kasutamine)))))))

(defun parse-opts (argv)
  (let ((optlist '("-h" "-n:" "-f:" "-s:"))
        (optargs '()))
    (loop for optspec in optlist do
          (multiple-value-bind (opt arg pos) (alexandria:getopt argv optspec)
            (when opt
              (push (cons opt arg) optargs)
              (setf argv (remove arg :test #'equal)))
            (when pos
              (setf argv (subseq argv pos)))))
    optargs))

|#
