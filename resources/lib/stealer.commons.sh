
function cdCurDir() {
    cd ${CUR_DIR}
}

function executeCommand() {
    ${COMMAND_NAME}_initialize $@
    ${COMMAND_NAME}_cmd $@
    return ${?}
}

function createDirectory() {
    DIRS_TO_CREATE=${@}
    for DIRECTORY in ${DIRS_TO_CREATE}; do
        if [ ! -d ${DIRECTORY} ]; then
            echo "Creating directory: ${DIRECTORY}"
            execute mkdir -p ${DIRECTORY}
        fi
    done
}

function execute() {
    echo ${@}
    ${@}
}
