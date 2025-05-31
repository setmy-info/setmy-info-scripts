# PLACEHOLDER-BEGIN #
MESSAGE("-- docker dependencies.cmake")

ADD_DEPENDENCIES(build buildDockerShellScripts buildDockerLibShells)
ADD_DEPENDENCIES(buildDockerShellScripts makeDirectories)
ADD_DEPENDENCIES(buildDockerLibShells makeDirectories)

# PLACEHOLDER-END #