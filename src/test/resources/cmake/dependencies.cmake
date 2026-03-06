# PLACEHOLDER-BEGIN #
MESSAGE("-- test dependencies.cmake")

IF (NOT WIN32)
    INCLUDE_CMAKE_FILE(${TEST_SH_CMAKE_PATH}/dependencies.cmake)
ENDIF()

# PLACEHOLDER-END #
