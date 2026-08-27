# PLACEHOLDER-BEGIN #
MESSAGE("-- server lib.cmake")

INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/elixir/smi-serve-files.exs" DESTINATION lib/elixir)
INSTALL(DIRECTORY "${LIBRARY_OUTPUT_PATH}/hello-server"           DESTINATION lib)

# PLACEHOLDER-END #
