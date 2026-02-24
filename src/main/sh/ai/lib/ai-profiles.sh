AI_PROFILE_SUFFIX="md"
HOME_AI_DIR=$(smi-home-location)/ai
SYSTEM_AI_PROFILES_DIR=$(ai-profiles-location)

createHomeAiFolder() {
    if [ ! -d "${HOME_AI_DIR}" ]; then
        mkdir -p ${HOME_AI_DIR}
    fi
}

executeAis() {
  PRINTABLE_AI_PROFILES=${*}
    for PRINTABLE_AI_PROFILE in ${PRINTABLE_AI_PROFILES}; do
      executeAi ${PRINTABLE_AI_PROFILE}
    done
}

executeAi() {
    PRINTABLE_AI_PROFILE=${*}
    AI_PROFILE_NAME=${PRINTABLE_AI_PROFILE}.${AI_PROFILE_SUFFIX}
    HOME_AI_PROFILE_FILE_NAME="${HOME_AI_DIR}/${AI_PROFILE_NAME}"
    SYSTEM_AI_PROFILE_FILE_NAME="${SYSTEM_AI_PROFILES_DIR}/${AI_PROFILE_NAME}"
    if [ -f "${HOME_AI_PROFILE_FILE_NAME}" ]; then
          cat "${HOME_AI_PROFILE_FILE_NAME}"
    elif [ -f "${SYSTEM_AI_PROFILE_FILE_NAME}" ]; then
          cat "${SYSTEM_AI_PROFILE_FILE_NAME}"
    fi
}
