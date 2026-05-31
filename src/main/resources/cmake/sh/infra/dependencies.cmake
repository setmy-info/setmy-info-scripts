# PLACEHOLDER-BEGIN #
MESSAGE("-- infra dependencies.cmake")

ADD_DEPENDENCIES(build          buildK8sYaml buildArgoYaml buildInfraMan)
ADD_DEPENDENCIES(buildK8sYaml   makeDirectories)
ADD_DEPENDENCIES(buildArgoYaml  makeDirectories)
ADD_DEPENDENCIES(buildInfraMan  makeDirectories buildMan)

# PLACEHOLDER-END #
