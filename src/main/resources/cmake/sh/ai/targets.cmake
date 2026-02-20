# PLACEHOLDER-BEGIN #
MESSAGE("-- ai targets.cmake")

ADD_CUSTOM_TARGET(buildAiMan cp ${AI_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/*.1)

# PLACEHOLDER-END #
