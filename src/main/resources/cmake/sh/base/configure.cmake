# PLACEHOLDER-BEGIN #
MESSAGE("-- base configure.cmake")

CONFIGURE_FILE("${MAIN_SH_SOURCES_PATH}/in/smi-location.in" "${BINARY_OUTPUT_PATH}/smi-location")
CONFIGURE_FILE("${MAIN_SH_SOURCES_PATH}/in/base.sh.in"      "${LIBRARY_OUTPUT_PATH}/base.sh")

# The systemd units and the environment file they read are generated from the installation
# directory and the var directory of this build, so that no unit and no drop-in writes the name
# of the project. @ONLY, because a unit may hold a ${VARIABLE} of its own, which is systemd's and
# not cmake's.
SET (SYSTEMD_SOURCES_PATH "${MAIN_SH_SOURCES_PATH}/etc/systemd/system")

CONFIGURE_FILE("${SYSTEMD_SOURCES_PATH}/environment.conf.in"
    "${ETC_OUTPUT_PATH}/environment.conf" @ONLY)
CONFIGURE_FILE("${SYSTEMD_SOURCES_PATH}/example.service.in"
    "${ETC_SYSTEM_OUTPUT_PATH}/example.service" @ONLY)
CONFIGURE_FILE("${SYSTEMD_SOURCES_PATH}/dagu.service.in"
    "${ETC_SYSTEM_OUTPUT_PATH}/dagu.service" @ONLY)
CONFIGURE_FILE("${SYSTEMD_SOURCES_PATH}/setmy-info-deploy.path.in"
    "${ETC_SYSTEM_OUTPUT_PATH}/setmy-info-deploy.path" @ONLY)
CONFIGURE_FILE("${SYSTEMD_SOURCES_PATH}/setmy-info-deploy.service.in"
    "${ETC_SYSTEM_OUTPUT_PATH}/setmy-info-deploy.service" @ONLY)
CONFIGURE_FILE("${SYSTEMD_SOURCES_PATH}/setmy-info-half-past.service.in"
    "${ETC_SYSTEM_OUTPUT_PATH}/setmy-info-half-past.service" @ONLY)
CONFIGURE_FILE("${SYSTEMD_SOURCES_PATH}/nginx.service.d/hardening.conf.in"
    "${ETC_SYSTEM_OUTPUT_PATH}/nginx.service.d/hardening.conf" @ONLY)

# PLACEHOLDER-END #
