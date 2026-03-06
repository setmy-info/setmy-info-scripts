# PLACEHOLDER-BEGIN #
MESSAGE("-- targets.cmake")

SET (CMAKE_VERBOSE_MAKEFILE TRUE)

ADD_CUSTOM_TARGET(build ALL)
ADD_CUSTOM_TARGET(clear)

ADD_CUSTOM_TARGET(makeDirectories
    COMMAND ${CMAKE_COMMAND} -E make_directory ${BUILD_PATH}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${MAN_OUTPUT_PATH}/man1
    COMMAND ${CMAKE_COMMAND} -E make_directory ${MAN_OUTPUT_PATH}/man2
    COMMAND ${CMAKE_COMMAND} -E make_directory ${MAN_OUTPUT_PATH}/man3
    COMMAND ${CMAKE_COMMAND} -E make_directory ${MAN_OUTPUT_PATH}/man4
    COMMAND ${CMAKE_COMMAND} -E make_directory ${MAN_OUTPUT_PATH}/man5
    COMMAND ${CMAKE_COMMAND} -E make_directory ${MAN_OUTPUT_PATH}/man6
    COMMAND ${CMAKE_COMMAND} -E make_directory ${MAN_OUTPUT_PATH}/man7
    COMMAND ${CMAKE_COMMAND} -E make_directory ${MAN_OUTPUT_PATH}/man8
    COMMAND ${CMAKE_COMMAND} -E make_directory ${MAN_OUTPUT_PATH}/man9
    COMMAND ${CMAKE_COMMAND} -E make_directory ${INFO_OUTPUT_PATH}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${LIBRARY_OUTPUT_PATH}/profiles
    COMMAND ${CMAKE_COMMAND} -E make_directory ${LIBRARY_OUTPUT_PATH}/profiles/ai
    COMMAND ${CMAKE_COMMAND} -E make_directory ${LIBRARY_OUTPUT_PATH}/packages
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ETC_PROFILED_OUTPUT_PATH}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${INCLUDE_OUTPUT_PATH}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ETC_SYSTEM_OUTPUT_PATH}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ETC_YUM_REPOS_PATH}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${SMI_VAR_PATH}
)

ADD_CUSTOM_TARGET(buildCmdScripts     ${CMAKE_COMMAND} -E copy_directory ${MAIN_CMD_SOURCES_PATH}/bin ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildCmdLib         ${CMAKE_COMMAND} -E copy_directory ${MAIN_CMD_SOURCES_PATH}/lib ${LIBRARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildGroovyScripts  ${CMAKE_COMMAND} -E copy_directory ${MAIN_GROOVY_SOURCES_PATH}/lib ${LIBRARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildPythonScripts  ${CMAKE_COMMAND} -E copy_directory ${MAIN_PYTHON_SOURCES_PATH}/lib ${LIBRARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildCLScripts      ${CMAKE_COMMAND} -E copy_directory ${MAIN_COMMON_LISP_SOURCES_PATH}/bin ${BINARY_OUTPUT_PATH} && ${CMAKE_COMMAND} -E copy_directory ${MAIN_COMMON_LISP_SOURCES_PATH}/lib ${LIBRARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(clearBuild          ${CMAKE_COMMAND} -E rm -rf ./${TARGET_PATH})
ADD_CUSTOM_TARGET(clearPkg            ${CMAKE_COMMAND} -E rm -rf ./${PROJECT_NAME}*.tar.gz ./${PROJECT_NAME}*.rpm ./${PROJECT_NAME}*.sh ./${PROJECT_NAME}*.deb ./${PROJECT_NAME}*.tar.Z ./${PROJECT_NAME}*.7z ./${PROJECT_NAME}*.tar.bz2 ./${PROJECT_NAME}*.tar.xz ./${PROJECT_NAME}*.zip)
ADD_CUSTOM_TARGET(clearCmake          ${CMAKE_COMMAND} -E rm -rf ./*.cmake ./_CPack_Packages install_manifest.cmake CMakeCache.cmake)
ADD_CUSTOM_TARGET(site)

IF (NOT WIN32)
    INCLUDE_CMAKE_FILE(${MAIN_SH_CMAKE_PATH}/targets.cmake)
ENDIF()

# PLACEHOLDER-END #
