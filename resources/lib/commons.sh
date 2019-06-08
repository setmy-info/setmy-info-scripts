
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

include() {
    FILE_TO_INCLUDE=$1
    if [ -f $FILE_TO_INCLUDE ]; then
        . $FILE_TO_INCLUDE
    fi
    return
}
