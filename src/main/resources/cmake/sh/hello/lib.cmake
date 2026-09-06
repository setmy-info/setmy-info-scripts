# PLACEHOLDER-BEGIN #
MESSAGE("-- hello lib.cmake")

INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/elixir/hello-elixir.exs" DESTINATION lib/elixir)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/cl/hello-lisp.lisp"      DESTINATION lib/cl)

# PLACEHOLDER-END #
