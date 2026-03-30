_AI_ETC_CONF="$(smi-etc-location)/ai.conf"
_AI_HOME_CONF="$(smi-home-location)/ai.conf"
if [ -f "${_AI_ETC_CONF}" ]; then
    . "${_AI_ETC_CONF}"
fi
if [ -f "${_AI_HOME_CONF}" ]; then
    . "${_AI_HOME_CONF}"
fi
unset _AI_ETC_CONF _AI_HOME_CONF
AI_KNOWLEDGE_APP_URL="${AI_KNOWLEDGE_APP_URL:-http://localhost:8800}"

executeAis() {
    DEFAULT_INCLUDED=0
    for PRINTABLE_AI_PROFILE in ${*}; do
        executeAi ${PRINTABLE_AI_PROFILE}
        if [ "${PRINTABLE_AI_PROFILE%%:*}" = "default" ]; then
            DEFAULT_INCLUDED=1
        fi
    done
    if [ ${DEFAULT_INCLUDED} -eq 0 ]; then
        executeAi default
    fi
}

_buildCategoriesJson() {
    CATS="${1}"
    JSON_CATS="["
    FIRST=1
    OLD_IFS="${IFS}"
    IFS=','
    for CAT in ${CATS}; do
        if [ ${FIRST} -eq 0 ]; then
            JSON_CATS="${JSON_CATS},"
        fi
        JSON_CATS="${JSON_CATS}\"${CAT}\""
        FIRST=0
    done
    IFS="${OLD_IFS}"
    JSON_CATS="${JSON_CATS}]"
    echo "${JSON_CATS}"
}

executeAi() {
    PRINTABLE_AI_PROFILE="${1}"

    # Parse name:cat1,cat2 format
    PROFILE_NAME="${PRINTABLE_AI_PROFILE%%:*}"
    if echo "${PRINTABLE_AI_PROFILE}" | grep -q ':'; then
        PROFILE_CATS="${PRINTABLE_AI_PROFILE#*:}"
    else
        PROFILE_CATS=""
    fi

    # Source ai.sh if present in current folder for variable overrides
    if [ -f "ai.sh" ]; then
        . ./ai.sh
    fi

    if [ -z "${JWT_TOKEN}" ]; then
        echo "ERROR: JWT_TOKEN environment variable is not set" >&2
        return 1
    fi

    # Build JSON request body
    if [ -n "${PROFILE_CATS}" ]; then
        CATS_JSON=$(_buildCategoriesJson "${PROFILE_CATS}")
        REQUEST_BODY="{\"ai\": [{\"name\": \"${PROFILE_NAME}\", \"categories\": ${CATS_JSON}}]}"
    else
        REQUEST_BODY="{\"ai\": [{\"name\": \"${PROFILE_NAME}\"}]}"
    fi

    # Fetch profile from remote knowledge app and apply variable substitution
    curl -s -X POST "${AI_KNOWLEDGE_APP_URL}/api/ai" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${JWT_TOKEN}" \
        -d "${REQUEST_BODY}" | envsubst
}
