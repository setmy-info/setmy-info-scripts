# PLACEHOLDER-BEGIN #
MESSAGE("-- hello dependencies.cmake")

ADD_DEPENDENCIES(build buildHelloBin buildHelloElixirLib buildHelloLispLib buildHelloMan)
ADD_DEPENDENCIES(buildHelloBin       makeDirectories)
ADD_DEPENDENCIES(buildHelloElixirLib makeDirectories)
ADD_DEPENDENCIES(buildHelloLispLib   makeDirectories)
ADD_DEPENDENCIES(buildHelloMan       makeDirectories)

# PLACEHOLDER-END #
