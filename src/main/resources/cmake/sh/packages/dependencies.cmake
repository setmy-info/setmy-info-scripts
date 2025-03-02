# PLACEHOLDER-BEGIN #
MESSAGE("-- packages dependencies.cmake")

ADD_DEPENDENCIES(build buildPackages buildPackagesLib)
ADD_DEPENDENCIES(buildPackages    makeDirectories)
ADD_DEPENDENCIES(buildPackagesLib makeDirectories)

# PLACEHOLDER-END #
