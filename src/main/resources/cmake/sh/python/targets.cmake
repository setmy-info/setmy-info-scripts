# PLACEHOLDER-BEGIN #
MESSAGE("-- python targets.cmake")

ADD_CUSTOM_TARGET(buildPythonShellScripts cp ${PYTHON_SH_SOURCES_BIN_PATH}/* ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildPythonMan          cp ${MAIN_MAN_SOURCES_PATH}/python/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/*.1)

# PLACEHOLDER-END #
