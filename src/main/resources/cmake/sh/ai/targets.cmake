# PLACEHOLDER-BEGIN #
MESSAGE("-- ai targets.cmake")

ADD_CUSTOM_TARGET(buildAiMan          cp ${AI_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/*.1)
ADD_CUSTOM_TARGET(buildAiShellScripts cp ${MAIN_SH_SOURCES_PATH}/ai/bin/* ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildAiLibShells    cp ${MAIN_SH_SOURCES_PATH}/ai/lib/*.sh ${LIBRARY_OUTPUT_PATH})

# PLACEHOLDER-END #
