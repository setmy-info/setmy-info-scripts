# PLACEHOLDER-BEGIN #
MESSAGE("-- base dependencies.cmake")

ADD_DEPENDENCIES(build buildAiMan buildAiShellScripts buildAiLibShells)

ADD_DEPENDENCIES(buildAiMan          makeDirectories)
ADD_DEPENDENCIES(buildAiShellScripts makeDirectories)
ADD_DEPENDENCIES(buildAiLibShells    makeDirectories)

# PLACEHOLDER-END #
