PROFILE_SUFFIX="profile"

createHomeTermFolder() {
    if [ ! -d "${COMMAND_HOME_FOLDER}" ]; then
        mkdir -p ${COMMAND_HOME_FOLDER}
    fi
}

loadProfiles() {
    LOADABLE_PROFILES=${*}
    # Filled by loaded profile (latest.profile)
    PROFILES=
    for LOADABLE_PROFILE in ${LOADABLE_PROFILES}; do
        HOME_PROFILE_FILE_NAME="${HOME}/.${COMMAND_NAME}/${LOADABLE_PROFILE}.${PROFILE_SUFFIX}"
        SYSTEM_PROFILE_FILE_NAME="${SYSTEM_PROFILES_DIR}/${LOADABLE_PROFILE}.${PROFILE_SUFFIX}"
        if [ -f "${HOME_PROFILE_FILE_NAME}" ]; then
            echo "Loading: ${HOME_PROFILE_FILE_NAME}"
            . ${HOME_PROFILE_FILE_NAME}
            loadProfiles ${PROFILES}
        elif [ -f "${SYSTEM_PROFILE_FILE_NAME}" ]; then
            echo "Loading: ${SYSTEM_PROFILE_FILE_NAME}"
            . ${SYSTEM_PROFILE_FILE_NAME}
            loadProfiles ${PROFILES}
        fi
    done
    return
}
