# PLACEHOLDER-BEGIN #
MESSAGE("-- base targets.cmake")

ADD_CUSTOM_TARGET(makeDirectories
    mkdir -p ${BUILD_PATH} &&
    mkdir -p ${MAN_OUTPUT_PATH}/man1 &&
    mkdir -p ${MAN_OUTPUT_PATH}/man2 &&
    mkdir -p ${MAN_OUTPUT_PATH}/man3 &&
    mkdir -p ${MAN_OUTPUT_PATH}/man4 &&
    mkdir -p ${MAN_OUTPUT_PATH}/man5 &&
    mkdir -p ${MAN_OUTPUT_PATH}/man6 &&
    mkdir -p ${MAN_OUTPUT_PATH}/man7 &&
    mkdir -p ${MAN_OUTPUT_PATH}/man8 &&
    mkdir -p ${MAN_OUTPUT_PATH}/man9 &&
    mkdir -p ${INFO_OUTPUT_PATH} &&
    mkdir -p ${LIBRARY_OUTPUT_PATH}/profiles &&
    mkdir -p ${LIBRARY_OUTPUT_PATH}/packages &&
    mkdir -p ${ETC_PROFILED_OUTPUT_PATH} &&
    mkdir -p ${INCLUDE_OUTPUT_PATH} &&
    mkdir -p ${ETC_SYSTEM_OUTPUT_PATH} &&
    mkdir -p ${ETC_YUM_REPOS_PATH} &&
    mkdir -p ${SMI_VAR_PATH}
)

ADD_CUSTOM_TARGET(buildMan             cp ${BASE_MAN_SOURCES_PATH}/man1/*.1 ${MAN_OUTPUT_PATH}/man1 && gzip -f ${MAN_OUTPUT_PATH}/man1/*.1)
ADD_CUSTOM_TARGET(buildEtc             cp -R ${MAIN_SH_SOURCES_PATH}/etc/profile.d/* ${ETC_OUTPUT_PATH}/profile.d)
ADD_CUSTOM_TARGET(buildLibShells       cp ${MAIN_SH_SOURCES_PATH}/lib/*.sh ${LIBRARY_OUTPUT_PATH} && cp ${MAIN_SH_SOURCES_PATH}/lib/*.txt ${LIBRARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildShellScripts    cp ${MAIN_SH_SOURCES_PATH}/bin/* ${BINARY_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildServiceScripts  cp ${MAIN_SH_SOURCES_PATH}/etc/systemd/system/*.service ${ETC_SYSTEM_OUTPUT_PATH} && cp ${MAIN_SH_SOURCES_PATH}/etc/systemd/system/environment.conf ${ETC_OUTPUT_PATH})
ADD_CUSTOM_TARGET(buildYumReposScripts cp ${MAIN_SH_SOURCES_PATH}/etc/yum.repos.d/*.repo ${ETC_YUM_REPOS_PATH})

# PLACEHOLDER-END #
