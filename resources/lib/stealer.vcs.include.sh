# TODO
# 1. VCS subfolder suport to move folders - inside repo take specific subfolder(s)
# 2. Combine all projects cleaned into one before moving to place (+ steps to change that)
# 3. 

smi_stealer_initialize() {
    prepareDirectories
    return 0
}

smi_stealer_cmd() {
    for PARAMETER in ${@}; do
        echo "Parameter: ${PARAMETER}"
    done
    iterateProjects
    return 0
}

prepareDirectories() {
    createDirectory ${CHECKOUT_DIR} ${CHECKOUT_ORIGINAL_DIR} ${CLEANED_DIR}
}

iterateProjects() {
    echo "## Cloning directories ##"
    for PROJECT_NAME in ${PROJECTS_NAMES}; do
        include ${REPOS_DIR}/${PROJECT_NAME}

        CHECKOUT_DESTINATION_DIR=${CHECKOUT_ORIGINAL_DIR}/${PROJECT_NAME}
        PROJECT_ORIGINAL_DIR=${CHECKOUT_ORIGINAL_DIR}/${PROJECT_NAME}
        CLEANED_DESTINATION_DIR=${CLEANED_DIR}/${PROJECT_NAME}

        cloneProject
        copyProjectsDirectories
        patching
        copyOnPlace

    done
}

cloneProject() {
    if [ ! -d "${CHECKOUT_DESTINATION_DIR}" ]; then
        echo "==> Cloning project: ${PROJECT_NAME} to ${CHECKOUT_DESTINATION_DIR}"
        execute ${REPO_TYPE} clone ${REPO_URL} ${CHECKOUT_DESTINATION_DIR}
        cd ${CHECKOUT_DESTINATION_DIR}
        execute ${REPO_TYPE} checkout ${REPO_BRANCH}
        execute ${REPO_TYPE} branch
        cdCurDir
    fi
}

copyProjectsDirectories() {
    echo "## Coping directories to cleaned folder ${CLEANED_DESTINATION_DIR} ##"
    createDirectory ${CLEANED_DESTINATION_DIR}
    if [ ! -z ${REPO_FOLDERS} ]; then
        for REPO_FOLDER in ${REPO_FOLDERS}; do
            execute cp -R ${PROJECT_ORIGINAL_DIR}/${REPO_FOLDER}/* ${CLEANED_DESTINATION_DIR}/
        done
    else
        execute cp -R ${PROJECT_ORIGINAL_DIR}/* ${CLEANED_DESTINATION_DIR}/
    fi
    REPO_FOLDERS=""
}

patching() {
    echo "## Post copy directories ##"
    if [ -d "${PATCH_DIR}" ]; then
        cd ${CLEANED_DESTINATION_DIR}

        postCopyProjectsDirectories
        patchProjectsDirectories
        changeProjectsDirectories
        
        cdCurDir
    fi
}

postCopyProjectsDirectories() {
    echo "## Post copy directories ##"
    if [ "$(ls ${PATCH_DIR}/*${PROJECT_NAME}.post.copy | wc -l)" -ge "1" ]; then
        COPY_FILE_NAMES=`ls ${PATCH_DIR}/*${PROJECT_NAME}.post.copy | sort`
        for COPY_FILE_NAME in ${COPY_FILE_NAMES}; do
            if [ -f ${COPY_FILE_NAME} ]; then
                include ${PCOPY_FILE_NAME}
            fi
        done
    else
        echo "No post copy files";
    fi;
}

patchProjectsDirectories() {
    echo "## Patch directories ##"
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

changeProjectsDirectories() {
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
    echo "## Copy on place ##"
    execute cp -R ${CLEANED_DESTINATION_DIR}/* ${CUR_DIR}/
}
