
cdCurDir() {
    cd ${CUR_DIR}
}

execute() {
    echo ${@}
    ${@}
}

createDirectory() {
    DIRS_TO_CREATE=${@}
    for DIRECTORY in ${DIRS_TO_CREATE}; do
        if [ ! -d ${DIRECTORY} ]; then
            echo "Creating directory: ${DIRECTORY}"
            execute mkdir -p ${DIRECTORY}
        fi
    done
}

include() {
    FILE_TO_INCLUDE=$1
    if [ -f ${FILE_TO_INCLUDE} ]; then
        echo "Including file: ${FILE_TO_INCLUDE}"
        . ${FILE_TO_INCLUDE}
    fi
    return
}

executeCommand() {
    ${COMMAND_NAME}_cmd $@
    return ${?}
}
