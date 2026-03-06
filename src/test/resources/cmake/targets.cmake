# PLACEHOLDER-BEGIN #
MESSAGE("-- test targets.cmake")

ADD_CUSTOM_TARGET(verify        @echo ============= Integration Test ========================)

IF (NOT WIN32)
    INCLUDE_CMAKE_FILE(${TEST_SH_CMAKE_PATH}/targets.cmake)
ENDIF()

# PLACEHOLDER-END #
