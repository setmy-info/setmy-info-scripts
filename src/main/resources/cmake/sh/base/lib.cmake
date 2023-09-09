# PLACEHOLDER-BEGIN #
MESSAGE("-- base lib.cmake")

INSTALL(DIRECTORY "${LIBRARY_OUTPUT_PATH}/profiles"                  DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/base.sh"                       DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/commons.sh"                    DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/konsole.sh"                    DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/profiles.sh"                   DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/packages.sh"                   DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/base64decode.py"               DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/base64encode.py"               DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/radians.groovy"                DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/degrees.groovy"                DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/uuid.groovy"                   DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/smi-cl-test.lisp"              DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/quicklisp-user-setup.lisp"     DESTINATION lib)

IF(DISTRIBUTION STREQUAL "FreeBSD")
#    INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/freebsd.sh"                DESTINATION lib)
ENDIF()

# PLACEHOLDER-END #
