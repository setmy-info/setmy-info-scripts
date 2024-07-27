# PLACEHOLDER-BEGIN #
MESSAGE("-- targets.cmake")

SET (CMAKE_VERBOSE_MAKEFILE TRUE)

ADD_CUSTOM_TARGET(build ALL)
ADD_CUSTOM_TARGET(clear)

ADD_CUSTOM_TARGET(buildGroovyScripts  cp ${MAIN_GROOVY_SOURCES_PATH}/lib/*.groovy ${LIBRARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildPythonScripts  cp ${MAIN_PYTHON_SOURCES_PATH}/lib/*.py ${LIBRARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildCLScripts      cp ${MAIN_COMMON_LISP_SOURCES_PATH}/bin/* ${BINARY_OUTPUT_PATH} && cp ${MAIN_COMMON_LISP_SOURCES_PATH}/lib/* ${LIBRARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(clearBuild          rm -rf ./${TARGET_PATH})
ADD_CUSTOM_TARGET(clearPkg            rm -rf ./${PROJECT_NAME}*.tar.gz ./${PROJECT_NAME}*.rpm ./${PROJECT_NAME}*.sh ./${PROJECT_NAME}*.deb ./${PROJECT_NAME}*.tar.Z ./${PROJECT_NAME}*.7z ./${PROJECT_NAME}*.tar.bz2 ./${PROJECT_NAME}*.tar.xz ./${PROJECT_NAME}*.zip)
ADD_CUSTOM_TARGET(clearCmake          rm -rf ./*.cmake ./_CPack_Packages install_manifest.cmake CMakeCache.cmake)
ADD_CUSTOM_TARGET(site)

INCLUDE_CMAKE_FILE(${MAIN_SH_CMAKE_PATH}/targets.cmake)
INCLUDE_CMAKE_FILE(${TEST_CMAKE_PATH}/targets.cmake)

# PLACEHOLDER-END #
