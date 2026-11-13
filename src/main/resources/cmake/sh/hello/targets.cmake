# PLACEHOLDER-BEGIN #
MESSAGE("-- hello targets.cmake")

ADD_CUSTOM_TARGET(buildHelloBin       cp ${MAIN_SH_SOURCES_PATH}/hello/bin/* ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildHelloElixirLib cp ${MAIN_ELIXIR_SOURCES_PATH}/hello/lib/hello-elixir.exs ${LIBRARY_ELIXIR_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildHelloLispLib   cp ${MAIN_COMMON_LISP_SOURCES_PATH}/hello/lib/hello-lisp.lisp ${LIBRARY_COMMON_LISP_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildHelloGroovyLib cp ${MAIN_GROOVY_SOURCES_PATH}/hello/lib/hello-groovy.groovy ${LIBRARY_GROOVY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildHelloMan       cp ${HELLO_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/hello-elixir.1 ${MAN_OUTPUT_PATH}/man1/hello-lisp.1 ${MAN_OUTPUT_PATH}/man1/hello-groovy.1)

# PLACEHOLDER-END #
