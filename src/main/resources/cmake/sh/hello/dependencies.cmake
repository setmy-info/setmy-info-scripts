# PLACEHOLDER-BEGIN #
MESSAGE("-- hello dependencies.cmake")

ADD_DEPENDENCIES(build buildHelloBin buildHelloElixirLib buildHelloLispLib buildHelloGroovyLib buildHelloPythonLib buildHelloClojureLib buildHelloMan)
ADD_DEPENDENCIES(buildHelloBin       makeDirectories)
ADD_DEPENDENCIES(buildHelloElixirLib makeDirectories)
ADD_DEPENDENCIES(buildHelloLispLib   makeDirectories)
ADD_DEPENDENCIES(buildHelloGroovyLib makeDirectories)
ADD_DEPENDENCIES(buildHelloPythonLib makeDirectories)
ADD_DEPENDENCIES(buildHelloClojureLib makeDirectories)
ADD_DEPENDENCIES(buildHelloMan       makeDirectories)

# PLACEHOLDER-END #
