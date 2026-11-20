(ns hello-clojure
  (:require [clj-uuid :as uuid]))

(def min-exit-code 0)
(def max-exit-code 255)
(def invalid-exit-code 1)

(defn parse-exit-code
  "Takes the command line arguments and returns the exit code to use.

  Returns 0 when no argument was given. Returns 1 when the argument is not an
  integer, or falls outside the 0..255 range a POSIX shell can report."
  [arguments]
  (if (empty? arguments)
    min-exit-code
    (try
      (let [value (Long/parseLong (first arguments))]
        (if (<= min-exit-code value max-exit-code)
          value
          invalid-exit-code))
      (catch NumberFormatException _
        invalid-exit-code))))

(defn print-exit-code
  "Prints the exit code when it is non-zero and stays silent otherwise.
  Returns the code unchanged so it can be passed onwards."
  [exit-code]
  (when-not (zero? exit-code)
    (println (str "Exiting with code " exit-code ".")))
  exit-code)

(println (str "Hello, world from " (.getCanonicalPath (java.io.File. ".")) " as UUID: " (uuid/v4) "!"))
(flush)

(System/exit (int (print-exit-code (parse-exit-code *command-line-args*))))
