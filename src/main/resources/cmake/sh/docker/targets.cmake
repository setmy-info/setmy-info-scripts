# PLACEHOLDER-BEGIN #
MESSAGE("-- docker targets.cmake")

ADD_CUSTOM_TARGET(buildDockerShellScripts cp ${MAIN_SH_SOURCES_PATH}/docker/bin/* ${BINARY_OUTPUT_PATH})

# PLACEHOLDER-END #