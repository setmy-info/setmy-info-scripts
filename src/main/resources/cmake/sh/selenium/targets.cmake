# PLACEHOLDER-BEGIN #
MESSAGE("-- selenium targets.cmake")

ADD_CUSTOM_TARGET(buildSeleniumShellScripts cp ${MAIN_SH_SOURCES_PATH}/selenium/bin/* ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildSeleniumMan          cp ${SELENIUM_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/*.1)

# PLACEHOLDER-END #
