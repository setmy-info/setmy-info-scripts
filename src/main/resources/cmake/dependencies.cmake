# PLACEHOLDER-BEGIN #
MESSAGE("-- dependencies.cmake")

ADD_DEPENDENCIES(build buildGroovyScripts buildPythonScripts buildCLScripts)
ADD_DEPENDENCIES(buildGroovyScripts makeDirectories)
ADD_DEPENDENCIES(buildPythonScripts makeDirectories)
ADD_DEPENDENCIES(buildCLScripts     makeDirectories)
ADD_DEPENDENCIES(clear clearCmake clearBuild clearPkg)

INCLUDE_CMAKE_FILE(${MAIN_SH_CMAKE_PATH}/dependencies.cmake)
INCLUDE_CMAKE_FILE(${MAIN_CPP_CMAKE_PATH}/dependencies.cmake)
INCLUDE_CMAKE_FILE(${TEST_CMAKE_PATH}/dependencies.cmake)

# PLACEHOLDER-END #
