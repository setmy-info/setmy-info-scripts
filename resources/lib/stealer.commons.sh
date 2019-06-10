
executeCommand() {
    ${COMMAND_NAME}_initialize $@
    ${COMMAND_NAME}_cmd $@
    return ${?}
}
