# PLACEHOLDER-BEGIN #
MESSAGE("-- infra bin.cmake")

INSTALL(PROGRAMS "${BINARY_OUTPUT_PATH}/smi-k8s-location"                   DESTINATION bin)
INSTALL(PROGRAMS "${BINARY_OUTPUT_PATH}/smi-argo-location"                  DESTINATION bin)
INSTALL(PROGRAMS "${BINARY_OUTPUT_PATH}/smi-k8s-pvc-name"                   DESTINATION bin)
INSTALL(PROGRAMS "${BINARY_OUTPUT_PATH}/smi-workflow-workspace-location"    DESTINATION bin)
INSTALL(PROGRAMS "${BINARY_OUTPUT_PATH}/smi-workflow-ai-workspace-location" DESTINATION bin)
INSTALL(PROGRAMS "${BINARY_OUTPUT_PATH}/smi-packages-shared-location"       DESTINATION bin)
INSTALL(PROGRAMS "${BINARY_OUTPUT_PATH}/smi-zfs-org-create"                 DESTINATION bin)
INSTALL(PROGRAMS "${BINARY_OUTPUT_PATH}/smi-k8s-secret-set"                 DESTINATION bin)
INSTALL(PROGRAMS "${BINARY_OUTPUT_PATH}/smi-k8s-configmap-set"              DESTINATION bin)

# PLACEHOLDER-END #
