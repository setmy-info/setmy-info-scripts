# PLACEHOLDER-BEGIN #
MESSAGE("-- workstation targets.cmake")

ADD_CUSTOM_TARGET(buildWorkstationBin cp ${MAIN_SH_SOURCES_PATH}/workstation/bin/smi-backup ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildWorkstationMan cp ${WORKSTATION_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/smi-backup.1)

# PLACEHOLDER-END #
