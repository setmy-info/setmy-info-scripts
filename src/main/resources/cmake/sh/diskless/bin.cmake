# PLACEHOLDER-BEGIN #
MESSAGE("-- diskless bin.cmake")

INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-make-diskless"    DESTINATION bin)
INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-diskless-passwd"  DESTINATION bin)
INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-diskless-useradd" DESTINATION bin)
INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-start-diskless"   DESTINATION bin)

# PLACEHOLDER-END #