# PLACEHOLDER-BEGIN #
MESSAGE("-- server dependencies.cmake")

ADD_DEPENDENCIES(build buildServerBin buildServerElixirLib buildServerMan buildServerHelloApp buildServerEtc)
ADD_DEPENDENCIES(buildServerBin       makeDirectories)
ADD_DEPENDENCIES(buildServerElixirLib makeDirectories)
ADD_DEPENDENCIES(buildServerMan       makeDirectories)
ADD_DEPENDENCIES(buildServerHelloApp  makeDirectories)
ADD_DEPENDENCIES(buildServerEtc       makeDirectories)

# PLACEHOLDER-END #
