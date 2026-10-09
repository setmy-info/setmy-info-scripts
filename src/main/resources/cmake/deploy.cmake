# PLACEHOLDER-BEGIN #
MESSAGE("-- deploy.cmake")

# Upload of the built package to a server and the hand over to the deployment service there.
#
# Nothing about any particular installation is in this repository: no host, no address, no port,
# no list of machines. Every value comes from the environment of the caller, so a CI job
# configuration or a command line decides which machine is deployed to, and this repository stays
# generic for anyone who clones it. src/main/sh/build/deploy.sh does the work and documents the
# variables; the ones that matter are:
#
#   SMI_DEPLOY_HOSTS   the servers, required: [user@]host[:port], several separated by spaces
#                      or commas, so one more machine is one more word
#   SMI_DEPLOY_USER    user for an entry that does not name one, default deploy
#   SMI_DEPLOY_PORT    port for an entry that does not name one, default 22
#
# The same package belongs on every machine: this project is the helper script collection that
# every VM, container host and server needs, not a per environment configuration, so one call
# deploys to the whole list and a further machine needs no change here:
#
#   SMI_DEPLOY_HOSTS="one.example.com two.example.com:2222" make deploy
#
# The package is not rebuilt by these targets: a release that was tested is the one that has to
# reach the server, so they fail when it is missing instead of building another.

# Built from the same parts packaging.cmake builds CPACK_PACKAGE_FILE_NAME from, not from that
# variable itself: include(CPack) has run by now and left it holding the source package name.
SET (DEPLOY_PACKAGE_NAME "${PROJECT_NAME}-${PROJECT_VERSION}.${ARCH_TYPE_SUFFIX}.rpm")
SET (DEPLOY_PACKAGE      "${PROJECT_PATH}/${DEPLOY_PACKAGE_NAME}")
SET (DEPLOY_SCRIPT       "${MAIN_SH_SOURCES_PATH}/build/deploy.sh")

MESSAGE("-- DEPLOY_PACKAGE:         ${DEPLOY_PACKAGE}")

ADD_CUSTOM_TARGET(upload
    COMMAND sh ${DEPLOY_SCRIPT} upload ${DEPLOY_PACKAGE}
    VERBATIM)

ADD_CUSTOM_TARGET(handover
    COMMAND sh ${DEPLOY_SCRIPT} handover ${DEPLOY_PACKAGE}
    VERBATIM)

ADD_CUSTOM_TARGET(deploy
    COMMAND sh ${DEPLOY_SCRIPT} deploy ${DEPLOY_PACKAGE}
    VERBATIM)

ADD_CUSTOM_TARGET(deploy-help
    COMMAND ${CMAKE_COMMAND} -E echo "make upload     upload ${DEPLOY_PACKAGE_NAME} to the server"
    COMMAND ${CMAKE_COMMAND} -E echo "make handover   move an uploaded package into the directory the deployment service watches"
    COMMAND ${CMAKE_COMMAND} -E echo "make deploy     both, which is what CI runs"
    COMMAND ${CMAKE_COMMAND} -E echo ""
    COMMAND ${CMAKE_COMMAND} -E echo "The servers come from the environment, never from this repository:"
    COMMAND ${CMAKE_COMMAND} -E echo "  SMI_DEPLOY_HOSTS='one.example.com two.example.com:2222' make deploy"
    COMMAND ${CMAKE_COMMAND} -E echo "  an entry is [user@]host[:port], several separated by spaces or commas"
    COMMAND ${CMAKE_COMMAND} -E echo "  SMI_DEPLOY_USER and SMI_DEPLOY_PORT fill in what an entry leaves out"
    COMMAND ${CMAKE_COMMAND} -E echo "  SMI_DEPLOY_REMOTE_DIR and SMI_DEPLOY_INCOMING_DIR override the directories"
    COMMAND ${CMAKE_COMMAND} -E echo ""
    COMMAND ${CMAKE_COMMAND} -E echo "Installation is done by the deployment service of the server, see journalctl -u setmy-info-deploy.service there"
    VERBATIM)

# PLACEHOLDER-END #
