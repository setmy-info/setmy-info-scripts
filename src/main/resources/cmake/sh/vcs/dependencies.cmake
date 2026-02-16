# PLACEHOLDER-BEGIN #
MESSAGE("-- vcs dependencies.cmake")

ADD_DEPENDENCIES(buildVCSMan makeDirectories)
ADD_DEPENDENCIES(buildVCSShellScripts buildVCSMan)
ADD_DEPENDENCIES(build buildVCSShellScripts)

# PLACEHOLDER-END #
