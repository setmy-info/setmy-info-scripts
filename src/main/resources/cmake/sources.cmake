# PLACEHOLDER-BEGIN #
MESSAGE("-- sources.cmake")

IF(EXISTS ${MAIN_CMAKE_PATH}/cpp/sources.cmake)
    INCLUDE(${MAIN_CMAKE_PATH}/cpp/sources.cmake)
ENDIF()

IF(EXISTS ${TEST_CMAKE_PATH}/cpp/sources.cmake)
    INCLUDE(${TEST_CMAKE_PATH}/cpp/sources.cmake)
ENDIF()

# PLACEHOLDER-END #
