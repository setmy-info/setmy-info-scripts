# PLACEHOLDER-BEGIN #
MESSAGE("-- selenium bin.cmake")

INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-selenium-hub"  DESTINATION bin)
INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-selenium-node" DESTINATION bin)
INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-selenium-standalone" DESTINATION bin)

# PLACEHOLDER-END #
