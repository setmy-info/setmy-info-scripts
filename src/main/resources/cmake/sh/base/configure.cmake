# PLACEHOLDER-BEGIN #
MESSAGE("-- base configure.cmake")

CONFIGURE_FILE("${MAIN_SH_SOURCES_PATH}/in/smi-location.in" "${BINARY_OUTPUT_PATH}/smi-location")
CONFIGURE_FILE("${MAIN_SH_SOURCES_PATH}/in/base.sh.in"      "${LIBRARY_OUTPUT_PATH}/base.sh")

# PLACEHOLDER-END #
