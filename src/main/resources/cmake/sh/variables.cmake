# PLACEHOLDER-BEGIN #
MESSAGE("-- sh variables.cmake")

#SET (PROVIDER "setmy.info")

IF (${CMAKE_SYSTEM_PROCESSOR} MATCHES i386|i586|i686)
#        set ( ARCH "32")
ELSE ()
#        set ( ARCH "64")
ENDIF ()

INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/base/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/cloud/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/crm/variables.cmake)
INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/diskless/variables.cmake)
INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/docker/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/infra/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/jail/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/packages/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/pki/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/python/variables.cmake)
INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/selenium/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/term/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/tools/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/vcs/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/virtualization/variables.cmake)
#INCLUDE_CMAKE_FILE(${MAIN_CMAKE_PATH}/sh/workstation/variables.cmake)

# PLACEHOLDER-END #
