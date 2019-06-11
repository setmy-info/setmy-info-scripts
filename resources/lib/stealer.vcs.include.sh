
createProject() {
    echo "# Creating project ${1}"
    PROJECT_NAME=${1}

    include ${REPOS_DIR}/${PROJECT_NAME}

    cloneProject ${PROJECT_NAME}
    checkoutProject ${PROJECT_NAME} ${REPO_BRANCH}
    copyProject ${PROJECT_NAME} ${REPO_BRANCH}
    changeProject ${PROJECT_NAME} ${REPO_BRANCH} # TODO : wrong place
}

cloneProject() {
    PROJECT_NAME=${1}
    CLONE_DESTINATION_DIR=${CLONE_DIR}/${PROJECT_NAME}
    if [ ! -d "${CLONE_DESTINATION_DIR}" ]; then
        echo "# Cloning project: ${PROJECT_NAME} to ${CLONE_DESTINATION_DIR}"
        execute ${REPO_TYPE} clone ${REPO_URL} ${CLONE_DESTINATION_DIR}
    fi
}

checkoutProject() {
    PROJECT_NAME=${1}
    BRANCH_NAME=${2}
    CLONE_DESTINATION_DIR=${CLONE_DIR}/${PROJECT_NAME}
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
    CLONE_DESTINATION_DIR=${CLONE_DIR}/${PROJECT_NAME}
    CLEANED_DESTINATION_DIR=${COPY_DIR}/${PROJECT_NAME}-${BRANCH_NAME}

    if [ ! -z ${REPO_FOLDERS} ]; then
        for REPO_FOLDER in ${REPO_FOLDERS}; do
            SOURCE_DIR=${CLONE_DESTINATION_DIR}/${REPO_FOLDER}
            DESTINATION_DIR=${CLEANED_DESTINATION_DIR}/${REPO_FOLDER}
            doCopy ${SOURCE_DIR} ${DESTINATION_DIR}
            REPO_FOLDERS=""
        done
    else
        SOURCE_DIR=${CLONE_DESTINATION_DIR}
        DESTINATION_DIR=${CLEANED_DESTINATION_DIR}
        doCopy ${SOURCE_DIR} ${DESTINATION_DIR}
    fi
}

doCopy() {
    SOURCE_DIR=${1}
    DESTINATION_DIR=${2}
    createDirectory ${DESTINATION_DIR}
    cp -R ${SOURCE_DIR}/* ${DESTINATION_DIR}/
}

changeProject() {
    echo "# Change project ${1}"
    PROJECT_NAME=${1}
    BRANCH_NAME=${2}
    CLEANED_DESTINATION_DIR=${COPY_DIR}/${PROJECT_NAME}-${BRANCH_NAME}
    if [ ! -z ${REPO_FOLDERS} ]; then
        for REPO_FOLDER in ${REPO_FOLDERS}; do
            DESTINATION_DIR=${CLEANED_DESTINATION_DIR}/${REPO_FOLDER}
            echo "Repo folder: ${REPO_FOLDER}"
            doChanges ${PROJECT_NAME} ${BRANCH_NAME} ${DESTINATION_DIR} ${REPO_FOLDER}
        done
    else
        DESTINATION_DIR=${CLEANED_DESTINATION_DIR}
        doChanges ${PROJECT_NAME} ${BRANCH_NAME} ${DESTINATION_DIR}
    fi
}

doChanges() {
    PROJECT_NAME=${1}
    BRANCH_NAME=${2}
    DESTINATION_DIR=${3}
    REPO_FOLDER=${4}

    cd ${DESTINATION_DIR}
    echo "In: `pwd`, ${REPO_FOLDER}"
    postCopyProjectChange ${PROJECT_NAME} ${BRANCH_NAME} ${REPO_FOLDER}
    patchProject ${PROJECT_NAME} ${BRANCH_NAME} ${REPO_FOLDER}
    postPatchChangeProject ${PROJECT_NAME} ${BRANCH_NAME} ${REPO_FOLDER}
    copyOnPlace ${PROJECT_NAME} ${BRANCH_NAME} ${REPO_FOLDER}
    cdCurDir
}

postCopyProjectChange() {
    PROJECT_NAME=${1}
    BRANCH_NAME=${2}
    REPO_FOLDER=${3}

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
    BRANCH_NAME=${2}
    REPO_FOLDER=${3}

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
    BRANCH_NAME=${2}
    REPO_FOLDER=${3}

    echo "# change project directories"
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
    BRANCH_NAME=${2}
    REPO_FOLDER=${3}
    
    DIR=`pwd`

    echo "# Copy on place ${PROJECT_NAME} ${BRANCH_NAME} ${REPO_FOLDER} in ${DIR}"
    if [ ! -z ${REPO_FOLDER} ]; then
        echo "WITH REPO FOLDER"
        execute cp -R ./${REPO_FOLDER}/* ${CUR_DIR}/
    else
        echo "NO REPO FOLDER"
        execute cp -R ./* ${CUR_DIR}/
    fi
}
