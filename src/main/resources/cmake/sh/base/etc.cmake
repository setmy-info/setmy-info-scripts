# PLACEHOLDER-BEGIN #
MESSAGE("-- base etc.cmake")

IF(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    INSTALL(DIRECTORY "${ETC_OUTPUT_PATH}/profile.d"                  DESTINATION etc)
    INSTALL(FILES "${ETC_OUTPUT_PATH}/environment.conf"               DESTINATION etc)
    INSTALL(FILES "${ETC_OUTPUT_PATH}/systemd/system/example.service" DESTINATION etc/systemd/system)
ENDIF()

# PLACEHOLDER-END #