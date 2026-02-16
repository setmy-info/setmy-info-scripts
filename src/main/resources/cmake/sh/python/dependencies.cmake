# PLACEHOLDER-BEGIN #
MESSAGE("-- python dependencies.cmake")

ADD_DEPENDENCIES(buildPythonShellScripts makeDirectories)
ADD_DEPENDENCIES(buildPythonMan          makeDirectories)

ADD_DEPENDENCIES(build buildPythonShellScripts buildPythonMan)

# PLACEHOLDER-END #
