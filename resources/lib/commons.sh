
function cdCurDir() {
    cd ${CUR_DIR}
}

function execute() {
    echo ${@}
    ${@}
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
