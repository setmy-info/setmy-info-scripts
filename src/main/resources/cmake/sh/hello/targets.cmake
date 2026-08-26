# PLACEHOLDER-BEGIN #
MESSAGE("-- hello targets.cmake")

ADD_CUSTOM_TARGET(buildHelloBin       cp ${MAIN_SH_SOURCES_PATH}/hello/bin/hello-elixir ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildHelloElixirLib cp ${MAIN_ELIXIR_SOURCES_PATH}/hello/lib/hello-elixir.exs ${LIBRARY_OUTPUT_PATH}/elixir)
ADD_CUSTOM_TARGET(buildHelloMan       cp ${HELLO_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/hello-elixir.1)

# PLACEHOLDER-END #
