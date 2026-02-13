# PLACEHOLDER-BEGIN #
MESSAGE("-- diskless targets.cmake")

ADD_CUSTOM_TARGET(buildDisklessShellScripts cp ${MAIN_SH_SOURCES_PATH}/diskless/bin/* ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildDisklessMan          cp ${DISKLESS_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/*.1)

# PLACEHOLDER-END #
