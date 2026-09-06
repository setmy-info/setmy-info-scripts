# PLACEHOLDER-BEGIN #
MESSAGE("-- workstation dependencies.cmake")

ADD_DEPENDENCIES(build buildWorkstationBin buildWorkstationMan)
ADD_DEPENDENCIES(buildWorkstationBin makeDirectories)
ADD_DEPENDENCIES(buildWorkstationMan makeDirectories)

# PLACEHOLDER-END #
