# PLACEHOLDER-BEGIN #
MESSAGE("-- packages dependencies.cmake")

ADD_DEPENDENCIES(build buildPackages buildPackagesLib buildPackagesBin)
ADD_DEPENDENCIES(buildPackages    makeDirectories)
ADD_DEPENDENCIES(buildPackagesLib makeDirectories)
ADD_DEPENDENCIES(buildPackagesBin makeDirectories)

# PLACEHOLDER-END #
