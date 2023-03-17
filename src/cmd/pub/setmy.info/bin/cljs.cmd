REM Unix vriant: clj -M --main cljs.main --compile hello-world.core --repl
REM clj --compile hello-world.core --repl
java -cp "%CLOJURE_JAR%;src" cljs.main %*
