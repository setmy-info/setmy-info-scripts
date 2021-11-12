cmake_minimum_required (VERSION 3.20.5)

# PLACEHOLDER-BEGIN #

PROJECT (setmy-info-scripts)

SET (PROJECT_VERSION_MAJOR              0)
SET (PROJECT_VERSION_MINOR              43)
SET (PROJECT_VERSION_PATCH              0)
SET (PROJECT_VERSION_TWEAK              0)

SET (PROJECT_DESCRIPTION_SUMMARY        "setmy.info scripts")
SET (PROJECT_DESCRIPTION                "setmy.info scripts Installation Example")
SET (PROJECT_VENDOR                     "Hear And See Systems LLC")
SET (PROJECT_MAINTAINER                 "Imre Tabur <imre.tabur@eesti.ee>")
SET (PROJECT_WWW                        "https://setmy.info")
SET (PROJECT_LICENSE                    "MIT")

INCLUDE(./resources/cmake/variables.txt)
INCLUDE(./resources/cmake/targets.txt)
INCLUDE(./resources/cmake/dependencies.txt)
INCLUDE(./resources/cmake/configure.txt)
INCLUDE(./resources/cmake/lib.txt)
INCLUDE(./resources/cmake/bin.txt)
INCLUDE(./resources/cmake/man.txt)
INCLUDE(./resources/cmake/etc.txt)

# PLACEHOLDER-PRE-PACKAGING #

INCLUDE(./resources/cmake/packaging.txt)

# PLACEHOLDER-END #
