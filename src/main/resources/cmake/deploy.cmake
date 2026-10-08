# PLACEHOLDER-BEGIN #
MESSAGE("-- deploy.cmake")

# Upload of the built package to the servers, the same way the nftables configuration does it:
# the deploy user, its public key already installed on both servers, BatchMode so a missing key
# fails instead of asking, scp -p into the deploy directory, and a listing afterwards.
#
# Only the RPM is uploaded, the servers are Rocky Linux and Fedora.
#
# The same package goes to every machine, TEST and LIVE alike: this project is the helper script
# collection that every VM, every container host and every server needs, not a per environment
# configuration. There is nothing to filter per environment, which is why "upload-all" exists.
#
# Every value can be overridden on the command line:
#   make upload-live DEPLOY_LIVE_HOST=host DEPLOY_LIVE_PORT=port DEPLOY_USER=user

SET (DEPLOY_USER        "deploy"           CACHE STRING "User the packages are uploaded as")
SET (DEPLOY_REMOTE_DIR  "/home/deploy/deploy" CACHE STRING "Directory the packages are uploaded into")

SET (DEPLOY_TEST_HOST   "lithium.gintra"   CACHE STRING "TEST server")
SET (DEPLOY_TEST_PORT   "22"               CACHE STRING "TEST server SSH port")

# LIVE listens on 27443, not on 22.
SET (DEPLOY_LIVE_HOST   "91.108.121.91"    CACHE STRING "LIVE front end server")
SET (DEPLOY_LIVE_PORT   "27443"            CACHE STRING "LIVE server SSH port")

# The back end server does not exist yet. Fill the host in, or pass it on the command line, and
# "make upload-be" works like the other two:
#   SET (DEPLOY_BE_HOST "91.108.121.93" CACHE STRING "LIVE back end server")
SET (DEPLOY_BE_HOST     ""                 CACHE STRING "LIVE back end server, empty until the VM exists")
SET (DEPLOY_BE_PORT     "27443"            CACHE STRING "LIVE back end server SSH port")

# Built from the same parts packaging.cmake builds CPACK_PACKAGE_FILE_NAME from, not from that
# variable itself: include(CPack) has run by now and left it holding the source package name.
SET (DEPLOY_PACKAGE_NAME "${PROJECT_NAME}-${PROJECT_VERSION}.${ARCH_TYPE_SUFFIX}.rpm")
SET (DEPLOY_PACKAGE      "${PROJECT_PATH}/${DEPLOY_PACKAGE_NAME}")

MESSAGE("-- DEPLOY_PACKAGE:         ${DEPLOY_PACKAGE}")
MESSAGE("-- DEPLOY_TEST:            ${DEPLOY_USER}@${DEPLOY_TEST_HOST}:${DEPLOY_TEST_PORT}${DEPLOY_REMOTE_DIR}")
MESSAGE("-- DEPLOY_LIVE:            ${DEPLOY_USER}@${DEPLOY_LIVE_HOST}:${DEPLOY_LIVE_PORT}${DEPLOY_REMOTE_DIR}")
MESSAGE("-- DEPLOY_BE:              ${DEPLOY_USER}@${DEPLOY_BE_HOST}:${DEPLOY_BE_PORT}${DEPLOY_REMOTE_DIR}")

# One upload target. The package is not rebuilt here: a release that was tested is the one that
# has to reach the server, so the target fails when it is missing instead of building another.
FUNCTION(ADD_UPLOAD_TARGET TARGET_NAME ENVIRONMENT_NAME HOST PORT)
    IF("${HOST}" STREQUAL "")
        ADD_CUSTOM_TARGET(${TARGET_NAME}
            COMMAND sh -c "echo '${ENVIRONMENT_NAME} server is not configured yet, set DEPLOY_BE_HOST in src/main/resources/cmake/deploy.cmake or pass it: make ${TARGET_NAME} DEPLOY_BE_HOST=host' >&2; exit 1"
            VERBATIM)
        RETURN()
    ENDIF()
    ADD_CUSTOM_TARGET(${TARGET_NAME}
        COMMAND sh -c "test -f '${DEPLOY_PACKAGE}' || { echo 'No package to upload: ${DEPLOY_PACKAGE}, run make package first' >&2; exit 1; }"
        COMMAND ${CMAKE_COMMAND} -E echo "Uploading to ${ENVIRONMENT_NAME}: ${DEPLOY_USER}@${HOST}:${DEPLOY_REMOTE_DIR} port ${PORT}"
        COMMAND ssh -o BatchMode=yes -p ${PORT} ${DEPLOY_USER}@${HOST} mkdir -p ${DEPLOY_REMOTE_DIR}
        COMMAND scp -o BatchMode=yes -p -P ${PORT} ${DEPLOY_PACKAGE} ${DEPLOY_USER}@${HOST}:${DEPLOY_REMOTE_DIR}/
        COMMAND ssh -o BatchMode=yes -p ${PORT} ${DEPLOY_USER}@${HOST} ls -l ${DEPLOY_REMOTE_DIR}
        COMMAND ${CMAKE_COMMAND} -E echo "Install it on ${ENVIRONMENT_NAME}, as a user who may: sudo dnf -y install ${DEPLOY_REMOTE_DIR}/${DEPLOY_PACKAGE_NAME}"
        VERBATIM)
ENDFUNCTION()

ADD_UPLOAD_TARGET(upload-test "TEST" "${DEPLOY_TEST_HOST}" "${DEPLOY_TEST_PORT}")
ADD_UPLOAD_TARGET(upload-live "LIVE" "${DEPLOY_LIVE_HOST}" "${DEPLOY_LIVE_PORT}")
ADD_UPLOAD_TARGET(upload-be   "LIVE back end" "${DEPLOY_BE_HOST}" "${DEPLOY_BE_PORT}")

ADD_CUSTOM_TARGET(upload)
ADD_DEPENDENCIES(upload upload-test)

# The same package belongs on every machine, so one target uploads it everywhere that is
# configured. The back end joins it by itself once DEPLOY_BE_HOST is set.
ADD_CUSTOM_TARGET(upload-all)
ADD_DEPENDENCIES(upload-all upload-test upload-live)
IF(NOT "${DEPLOY_BE_HOST}" STREQUAL "")
    ADD_DEPENDENCIES(upload-all upload-be)
ENDIF()

ADD_CUSTOM_TARGET(upload-help
    COMMAND ${CMAKE_COMMAND} -E echo "make upload-test   upload ${DEPLOY_PACKAGE_NAME} to ${DEPLOY_USER}@${DEPLOY_TEST_HOST} port ${DEPLOY_TEST_PORT}"
    COMMAND ${CMAKE_COMMAND} -E echo "make upload-live   upload it to ${DEPLOY_USER}@${DEPLOY_LIVE_HOST} port ${DEPLOY_LIVE_PORT}"
    COMMAND ${CMAKE_COMMAND} -E echo "make upload-be     upload it to the back end server, DEPLOY_BE_HOST has to be set"
    COMMAND ${CMAKE_COMMAND} -E echo "make upload        the same as upload-test"
    COMMAND ${CMAKE_COMMAND} -E echo "make upload-all    upload it to every configured environment, the same package belongs on all of them"
    COMMAND ${CMAKE_COMMAND} -E echo "into ${DEPLOY_REMOTE_DIR} as ${DEPLOY_USER}, with the key that is already installed there"
    COMMAND ${CMAKE_COMMAND} -E echo "override: make upload-live DEPLOY_LIVE_HOST=host DEPLOY_LIVE_PORT=port DEPLOY_USER=user DEPLOY_REMOTE_DIR=dir"
    VERBATIM)

# PLACEHOLDER-END #
