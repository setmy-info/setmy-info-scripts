# PLACEHOLDER-BEGIN #
MESSAGE("-- docker targets.cmake")

ADD_CUSTOM_TARGET(buildDockerShellScripts cp ${MAIN_SH_SOURCES_PATH}/docker/bin/* ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildDockerLibShells    cp ${MAIN_SH_SOURCES_PATH}/docker/lib/* ${LIBRARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildDockerMan          cp ${DOCKER_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/*.1)

# PLACEHOLDER-END #