# PLACEHOLDER-BEGIN #
MESSAGE("-- base dependencies.cmake")

ADD_DEPENDENCIES(build buildMan buildShellScripts buildEtc buildLibShells)

ADD_DEPENDENCIES(buildMan           makeDirectories)
ADD_DEPENDENCIES(buildShellScripts  makeDirectories)
ADD_DEPENDENCIES(buildEtc           makeDirectories)
ADD_DEPENDENCIES(buildLibShells     makeDirectories)

ADD_DEPENDENCIES(build buildProfiles buildPackages buildServiceScripts buildYumReposScripts)
ADD_DEPENDENCIES(buildProfiles makeDirectories)
ADD_DEPENDENCIES(buildPackages makeDirectories)
ADD_DEPENDENCIES(buildServiceScripts buildYumReposScripts makeDirectories)

# PLACEHOLDER-END #
