# PLACEHOLDER-BEGIN #
MESSAGE("-- python bin.cmake")

INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-create-venv"  DESTINATION bin)
INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-prepare-venv" DESTINATION bin)
INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-python"       DESTINATION bin)
INSTALL(PROGRAMS  "${BINARY_OUTPUT_PATH}/smi-venv-command" DESTINATION bin)

# PLACEHOLDER-END #
