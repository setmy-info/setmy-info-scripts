# PLACEHOLDER-BEGIN #
MESSAGE("-- base dependencies.cmake")

ADD_DEPENDENCIES(build buildMan buildShellScripts buildEtc buildLibShells)

ADD_DEPENDENCIES(buildMan           makeDirectories)
ADD_DEPENDENCIES(buildShellScripts  makeDirectories)
ADD_DEPENDENCIES(buildEtc           makeDirectories)
ADD_DEPENDENCIES(buildLibShells     makeDirectories)

ADD_DEPENDENCIES(build buildProfiles buildServiceScripts)
ADD_DEPENDENCIES(buildProfiles makeDirectories)
ADD_DEPENDENCIES(buildServiceScripts makeDirectories)

# PLACEHOLDER-END #