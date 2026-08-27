# PLACEHOLDER-BEGIN #
MESSAGE("-- server dependencies.cmake")

ADD_DEPENDENCIES(build buildServerBin buildServerElixirLib buildServerMan buildServerHelloApp)
ADD_DEPENDENCIES(buildServerBin       makeDirectories)
ADD_DEPENDENCIES(buildServerElixirLib makeDirectories)
ADD_DEPENDENCIES(buildServerMan       makeDirectories)
ADD_DEPENDENCIES(buildServerHelloApp  makeDirectories)

# PLACEHOLDER-END #
