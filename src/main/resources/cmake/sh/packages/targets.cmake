# PLACEHOLDER-BEGIN #
MESSAGE("-- packages targets.cmake")

ADD_CUSTOM_TARGET(buildPackages    cp -R ${MAIN_SH_SOURCES_PATH}/packages/lib/packages/* ${LIBRARY_OUTPUT_PATH}/packages)
ADD_CUSTOM_TARGET(buildPackagesLib cp ${MAIN_SH_SOURCES_PATH}/packages/lib/*.sh ${LIBRARY_OUTPUT_PATH})

# PLACEHOLDER-END #
