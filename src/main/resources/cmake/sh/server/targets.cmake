# PLACEHOLDER-BEGIN #
MESSAGE("-- server targets.cmake")

ADD_CUSTOM_TARGET(buildServerBin       cp ${MAIN_SH_SOURCES_PATH}/server/bin/* ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildServerElixirLib cp ${MAIN_ELIXIR_SOURCES_PATH}/server/lib/*.exs ${LIBRARY_OUTPUT_PATH}/elixir)
ADD_CUSTOM_TARGET(buildServerMan       cp ${SERVER_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/smi-serve-files.1)
# The example app ships with the toolset, not under an organization: the applications directory
# is per organization and is only known at deploy time, so it is copied there by hand.
ADD_CUSTOM_TARGET(buildServerHelloApp  mkdir -p ${LIBRARY_OUTPUT_PATH}/hello-server && cp -R ${MAIN_HTML_SOURCES_PATH}/hello-server/. ${LIBRARY_OUTPUT_PATH}/hello-server)

# PLACEHOLDER-END #
