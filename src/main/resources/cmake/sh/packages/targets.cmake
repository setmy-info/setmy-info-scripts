# PLACEHOLDER-BEGIN #
MESSAGE("-- packages targets.cmake")

ADD_CUSTOM_TARGET(buildPackages    cp -R ${MAIN_SH_SOURCES_PATH}/packages/lib/packages/* ${LIBRARY_OUTPUT_PATH}/packages)
ADD_CUSTOM_TARGET(buildPackagesBin cp -R ${MAIN_SH_SOURCES_PATH}/packages/bin/* ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildPackagesLib cp ${MAIN_SH_SOURCES_PATH}/packages/lib/*.sh ${LIBRARY_OUTPUT_PATH})
#ADD_CUSTOM_TARGET(buildPackagesMan cp ${PACKAGES_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/*.1)

# PLACEHOLDER-END #
