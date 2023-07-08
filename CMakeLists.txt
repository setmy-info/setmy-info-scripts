cmake_minimum_required (VERSION 3.25.2)

# PLACEHOLDER-BEGIN #

PROJECT (setmy-info-scripts)

SET (PROJECT_VERSION_MAJOR              0)
SET (PROJECT_VERSION_MINOR              56)
SET (PROJECT_VERSION_PATCH              0)
SET (PROJECT_VERSION_TWEAK              0)

SET (PROJECT_DESCRIPTION_SUMMARY        "setmy.info scripts")
SET (PROJECT_DESCRIPTION                "setmy.info scripts Installation Example")
SET (PROJECT_VENDOR                     "Hear And See Systems LLC")
SET (PROJECT_MAINTAINER                 "Imre Tabur <imre.tabur@mail.ee>")
SET (PROJECT_WWW                        "https://setmy.info")
SET (PROJECT_LICENSE                    "MIT")

INCLUDE(./src/main/resources/cmake/functions.txt)
INCLUDE(./src/main/resources/cmake/variables.txt)
INCLUDE(./src/main/resources/cmake/sources.txt)
INCLUDE(./src/main/resources/cmake/targets.txt)
INCLUDE(./src/main/resources/cmake/dependencies.txt)
INCLUDE(./src/main/resources/cmake/configure.txt)
INCLUDE(./src/main/resources/cmake/lib.txt)
INCLUDE(./src/main/resources/cmake/bin.txt)
INCLUDE(./src/main/resources/cmake/man.txt)
INCLUDE(./src/main/resources/cmake/etc.txt)

# PLACEHOLDER-PRE-PACKAGING #

INCLUDE(./src/main/resources/cmake/packaging.txt)

# PLACEHOLDER-END #
