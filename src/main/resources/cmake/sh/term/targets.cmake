# PLACEHOLDER-BEGIN #
MESSAGE("-- term targets.cmake")

ADD_CUSTOM_TARGET(buildTermMan cp ${TERM_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/*.1)
ADD_CUSTOM_TARGET(buildProfiles cp -R ${MAIN_SH_SOURCES_PATH}/term/lib/profiles/* ${LIBRARY_OUTPUT_PATH}/profiles)

# PLACEHOLDER-END #
