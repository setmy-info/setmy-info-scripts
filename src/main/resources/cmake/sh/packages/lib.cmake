# PLACEHOLDER-BEGIN #
MESSAGE("-- packages lib.cmake")

INSTALL(DIRECTORY "${LIBRARY_OUTPUT_PATH}/packages"                  DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/packages.sh"                   DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/versions-spider.groovy"        DESTINATION lib)

# PLACEHOLDER-END #
