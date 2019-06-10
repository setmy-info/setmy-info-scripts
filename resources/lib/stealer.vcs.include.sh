
smi_stealer_cmd() {
    for PARAMETER in ${@}; do
        echo "Parameter: ${PARAMETER}"
    done
    createProjects
    return 0
}

createProjects() {
    echo "# Creating projects: ${PROJECTS_NAMES}"
    for PROJECT_NAME in ${PROJECTS_NAMES}; do
        createProject ${PROJECT_NAME}
    done
}

createProject() {
    echo "# Creating project ${1}"
    PROJECT_NAME=${1}

    include ${REPOS_DIR}/${PROJECT_NAME}

    cloneProject ${PROJECT_NAME}
    checkoutProject ${PROJECT_NAME} ${REPO_BRANCH}
    copyProject ${PROJECT_NAME} ${REPO_BRANCH}
    changeProject ${PROJECT_NAME}
    copyOnPlace ${PROJECT_NAME}
}

cloneProject() {
    PROJECT_NAME=${1}
    CLONE_DESTINATION_DIR=${CLONE_ORIGINAL_DIR}/${PROJECT_NAME}
    if [ ! -d "${CLONE_DESTINATION_DIR}" ]; then
        echo "# Cloning project: ${PROJECT_NAME} to ${CLONE_DESTINATION_DIR}"
        execute ${REPO_TYPE} clone ${REPO_URL} ${CLONE_DESTINATION_DIR}
    fi
}

checkoutProject() {
    PROJECT_NAME=${1}
    BRANCH_NAME=${2}
    CLONE_DESTINATION_DIR=${CLONE_ORIGINAL_DIR}/${PROJECT_NAME}
    if [ -d "${CLONE_DESTINATION_DIR}" ]; then
        echo "# Checkout project ${PROJECT_NAME} in ${CLONE_DESTINATION_DIR} to branch/tag/hash ${BRANCH_NAME}"
        cd ${CLONE_DESTINATION_DIR}
        execute ${REPO_TYPE} checkout ${BRANCH_NAME}
        cdCurDir
    fi
}

copyProject() {
    PROJECT_NAME=${1}
    BRANCH_NAME=${2}
    CLEANED_DESTINATION_DIR=${CLEANED_DIR}/${PROJECT_NAME}- ${BRANCH_NAME}
    echo "# Coping project ${PROJECT_NAME} to ${CLEANED_DESTINATION_DIR}"
    if [ ! -z ${REPO_FOLDERS} ]; then
        for REPO_FOLDER in ${REPO_FOLDERS}; do
            DESTINATION_DIR=${CLEANED_DESTINATION_DIR}/${REPO_FOLDER}/
        done
    else
        DESTINATION_DIR=${CLEANED_DESTINATION_DIR}/
    fi
    execute cp -R ${PROJECT_ORIGINAL_DIR}/* ${DESTINATION_DIR}
    REPO_FOLDERS=""
}

changeProject() {
    echo "# Change project ${1}"
    PROJECT_NAME=${1}
    if [ ! -z ${REPO_FOLDERS} ]; then
        for REPO_FOLDER in ${REPO_FOLDERS}; do
            DESTINATION_DIR=${CLEANED_DESTINATION_DIR}/${REPO_FOLDER}/
        done
    else
        DESTINATION_DIR=${CLEANED_DESTINATION_DIR}/
    fi

    cd ${DESTINATION_DIR}
    postCopyProjectChange ${PROJECT_NAME}
    patchProject ${PROJECT_NAME}
    postPatchChangeProject ${PROJECT_NAME}
    cdCurDir
}

postCopyProjectChange() {
    PROJECT_NAME=${1}
    echo "# Post copy procjet ${PROJECT_NAME}"
    if [ "$(ls ${PATCH_DIR}/*${PROJECT_NAME}.post.copy | wc -l)" -ge "1" ]; then
        COPY_FILE_NAMES=`ls ${PATCH_DIR}/*${PROJECT_NAME}.post.copy | sort`
        for COPY_FILE_NAME in ${COPY_FILE_NAMES}; do
            echo "Including ${COPY_FILE_NAME} for ${PROJECT_NAME}"
            if [ -f ${COPY_FILE_NAME} ]; then
                include ${COPY_FILE_NAME}
            fi
        done
    else
        echo "No post copy files";
    fi;
}

patchProject() {
    PROJECT_NAME=${1}
    echo "# Patch procjet ${PROJECT_NAME}"
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
}

postPatchChangeProject() {
    PROJECT_NAME=${1}
    echo "## change project directories ##"
    if [ "$(ls ${PATCH_DIR}/*${PROJECT_NAME}.post.copy | wc -l)" -ge "1" ]; then
        CHANGE_FILE_NAMES=`ls ${PATCH_DIR}/*${PROJECT_NAME}.change | sort`
        for CHANGE_FILE_NAME in ${CHANGE_FILE_NAMES}; do
            if [ -f ${CHANGE_FILE_NAME} ]; then
                include ${CHANGE_FILE_NAME}
            fi
        done
    else
        echo "No post copy files";
    fi;
}

copyOnPlace() {
    PROJECT_NAME=${1}
    echo "## Copy on place ##"
    # TODO : when subfolders
    execute cp -R ${CLEANED_DESTINATION_DIR}/* ${CUR_DIR}/
}
