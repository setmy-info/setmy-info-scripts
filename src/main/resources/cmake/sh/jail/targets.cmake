# PLACEHOLDER-BEGIN #
MESSAGE("-- jail targets.cmake")

ADD_CUSTOM_TARGET(buildJailMan cp ${JAIL_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/*.1)

# PLACEHOLDER-END #
