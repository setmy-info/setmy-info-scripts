# TODO
# 1. VCS subfolder suport to move folders - inside repo take specific subfolder(s)
# 2. Combine all projects cleaned into one before moving to place (+ steps to change that)
# 3. 

function smi_stealer_initialize() {
    prepareDirectories
    return 0
}

function smi_stealer_cmd() {
    for PARAMETER in ${@}; do
        echo "Parameter: ${PARAMETER}"
    done
    cloneDirectories
    postCopyProjectsDirectories
    patchProjectsDirectories
    changeProjectsDirectories
    copyOnPlace
    return 0
}

function prepareDirectories() {
    createDirectory ${CHECKOUT_DIR} ${CHECKOUT_ORIGINAL_DIR} ${CLEANED_DIR}
}

function cloneDirectories() {
    echo "## Cloning directories ##"
    for PROJECT_NAME in ${PROJECTS_NAMES}; do
        include ${REPOS_DIR}/${PROJECT_NAME}
        CHECKOUT_DESTINATION_DIR=${CHECKOUT_ORIGINAL_DIR}/${PROJECT_NAME}
        if [ ! -d "${CHECKOUT_DESTINATION_DIR}" ]; then
            echo "Cloning project: ${PROJECT_NAME}"
            execute ${REPO_TYPE} clone ${REPO_URL} ${CHECKOUT_DESTINATION_DIR}
            cd ${CHECKOUT_DESTINATION_DIR}
            execute ${REPO_TYPE} checkout ${REPO_BRANCH}
            execute ${REPO_TYPE} branch
            cdCurDir
        fi
        copyProjectsDirectories
    done
}

function copyProjectsDirectories() {
    echo "## Coping directories ##"
    PROJECT_ORIGINAL_DIR=${CHECKOUT_ORIGINAL_DIR}/${PROJECT_NAME}
    CLEANED_DESTINATION_DIR=${CLEANED_DIR}/${PROJECT_NAME}
    createDirectory ${CLEANED_DESTINATION_DIR}
    echo "Repo folders: ${REPO_FOLDERS}"
    if [ ! -z ${REPO_FOLDERS} ]; then
        echo "Have repo folders to copy"
        for REPO_FOLDER in ${REPO_FOLDERS}; do
            cp -R ${PROJECT_ORIGINAL_DIR}/${REPO_FOLDER}/* ${CLEANED_DESTINATION_DIR}/
        done
    else
        echo "Doesn't have repo folders to copy"
        cp -R ${PROJECT_ORIGINAL_DIR}/* ${CLEANED_DESTINATION_DIR}/
    fi
    REPO_FOLDERS=""
}

function postCopyProjectsDirectories() {
    echo "## Post copy directories ##"
    if [ -d "${PATCH_DIR}" ]; then
        for PROJECT_NAME in ${PROJECTS_NAMES}; do
            CLEANED_DESTINATION_DIR=${CLEANED_DIR}/${PROJECT_NAME}
            cd ${CLEANED_DESTINATION_DIR}

            if [ "$(ls ${PATCH_DIR}/*${PROJECT_NAME}.post.copy | wc -l)" -ge "1" ]; then
                PATCH_NAMES=`ls ${PATCH_DIR}/*${PROJECT_NAME}.post.copy | sort`
                for PATCH_NAME in ${PATCH_NAMES}; do
                    if [ -f ${PATCH_NAME} ]; then
                        . ${PATCH_NAME}
                    fi
                done
            else
                echo "No post copy files";
            fi;

            cdCurDir
        done
    fi
}

function patchProjectsDirectories() {
    echo "## Patch directories ##"
    if [ -d "${PATCH_DIR}" ]; then
        for PROJECT_NAME in ${PROJECTS_NAMES}; do
            CLEANED_DESTINATION_DIR=${CLEANED_DIR}/${PROJECT_NAME}
            cd ${CLEANED_DESTINATION_DIR}

            if [ "$(ls ${PATCH_DIR}/*${PROJECT_NAME}.patch | wc -l)" -ge "1" ]; then
                PATCH_NAMES=`ls ${PATCH_DIR}/*${PROJECT_NAME}.patch | sort`
                for PATCH_NAME in ${PATCH_NAMES}; do
                if [ -f ${PATCH_NAME} ]; then
                    patch -f -s -p1 < ${PATCH_NAME}
                fi
                done
            else
                echo "No patch files";
            fi;

            cdCurDir
        done
    fi
}

function changeProjectsDirectories() {
    echo "## change project directories ##"
    if [ -d "${PATCH_DIR}" ]; then
        for PROJECT_NAME in ${PROJECTS_NAMES}; do
            CLEANED_DESTINATION_DIR=${CLEANED_DIR}/${PROJECT_NAME}
            cd ${CLEANED_DESTINATION_DIR}

            if [ "$(ls ${PATCH_DIR}/*${PROJECT_NAME}.post.copy | wc -l)" -ge "1" ]; then
                PATCH_NAMES=`ls ${PATCH_DIR}/*${PROJECT_NAME}.change | sort`
                for PATCH_NAME in ${PATCH_NAMES}; do
                    if [ -f ${PATCH_NAME} ]; then
                        . ${PATCH_NAME}
                    fi
                done
            else
                echo "No post copy files";
            fi;

            cdCurDir
        done
    fi
}

function copyOnPlace() {
    echo "## Copy on place ##"
    for PROJECT_NAME in ${PROJECTS_NAMES}; do
        CLEANED_DESTINATION_DIR=${CLEANED_DIR}/${PROJECT_NAME}
        cp -R ${CLEANED_DESTINATION_DIR}/* ${CUR_DIR}/
        cdCurDir
    done
}
