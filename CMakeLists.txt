cmake_minimum_required (VERSION 3.25.2)

# PLACEHOLDER-BEGIN #

PROJECT (setmy-info-scripts)

SET (PROJECT_VERSION_MAJOR              0)
SET (PROJECT_VERSION_MINOR              91)
SET (PROJECT_VERSION_PATCH              0)
SET (PROJECT_VERSION_TWEAK              0)

SET (PROJECT_DESCRIPTION_SUMMARY        "setmy.info scripts")
SET (PROJECT_DESCRIPTION                "setmy.info scripts Installation Example")
SET (PROJECT_VENDOR                     "Hear And See Systems LLC")
SET (PROJECT_MAINTAINER                 "Imre Tabur <imre.tabur@mail.ee>")
SET (PROJECT_WWW                        "https://setmy.info")
SET (PROJECT_LICENSE                    "MIT")

enable_testing()

INCLUDE(./src/main/resources/cmake/functions.cmake)
INCLUDE(./src/test/resources/cmake/functions.cmake)
INCLUDE(./src/main/resources/cmake/variables.cmake)
INCLUDE(./src/test/resources/cmake/variables.cmake)
INCLUDE(./src/main/resources/cmake/sources.cmake)
INCLUDE(./src/test/resources/cmake/sources.cmake)
INCLUDE(./src/main/resources/cmake/targets.cmake)
INCLUDE(./src/test/resources/cmake/targets.cmake)
INCLUDE(./src/main/resources/cmake/dependencies.cmake)
INCLUDE(./src/test/resources/cmake/dependencies.cmake)
INCLUDE(./src/main/resources/cmake/configure.cmake)
INCLUDE(./src/test/resources/cmake/configure.cmake)
INCLUDE(./src/main/resources/cmake/lib.cmake)
INCLUDE(./src/test/resources/cmake/lib.cmake)
INCLUDE(./src/main/resources/cmake/bin.cmake)
INCLUDE(./src/test/resources/cmake/bin.cmake)
INCLUDE(./src/main/resources/cmake/man.cmake)
INCLUDE(./src/test/resources/cmake/man.cmake)
INCLUDE(./src/main/resources/cmake/etc.cmake)
INCLUDE(./src/test/resources/cmake/etc.cmake)
INCLUDE(./src/main/resources/cmake/var.cmake)
INCLUDE(./src/test/resources/cmake/var.cmake)

# PLACEHOLDER-PRE-PACKAGING #

INCLUDE(./src/main/resources/cmake/packaging.cmake)

# PLACEHOLDER-END #
