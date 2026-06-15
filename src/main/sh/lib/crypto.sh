
ENCRYPTED_FILE_SUFFIX=enc
# 600 000 iterations meets NIST SP 800-132 / OWASP 2023 minimum for PBKDF2-SHA-256
ENCRYPTION_ITERATIONS=600000

encryptFile() {
    FILE_NAME="${1}"
    if [ ! -f "${FILE_NAME}" ]; then
        printf 'ERROR: "%s" does not exist or is not a regular file.\n' "${FILE_NAME}" >&2
        exit 1
    fi

    ENCRYPTED_FILE="${FILE_NAME}.${ENCRYPTED_FILE_SUFFIX}"
    HMAC_FILE="${ENCRYPTED_FILE}.hmac"

    printf 'Enter passphrase: ' >&2
    stty -echo 2>/dev/null
    read PASSPHRASE
    stty echo 2>/dev/null
    printf '\n' >&2

    printf 'Repeat passphrase: ' >&2
    stty -echo 2>/dev/null
    read PASSPHRASE2
    stty echo 2>/dev/null
    printf '\n' >&2

    if [ "${PASSPHRASE}" != "${PASSPHRASE2}" ]; then
        printf 'ERROR: passphrases do not match.\n' >&2
        exit 1
    fi

    printf '%s\n' "${PASSPHRASE}" | \
        openssl enc -aes-256-cbc -salt -pbkdf2 -md sha256 \
            -iter "${ENCRYPTION_ITERATIONS}" \
            -in "${FILE_NAME}" -out "${ENCRYPTED_FILE}" -pass stdin
    RESULT_CODE=${?}

    if [ "${RESULT_CODE}" -ne 0 ] || [ ! -s "${ENCRYPTED_FILE}" ]; then
        printf 'ERROR: encryption failed or produced an empty file.\n' >&2
        rm -f "${ENCRYPTED_FILE}"
        exit 2
    fi

    openssl dgst -sha512 -hmac "${PASSPHRASE}" "${ENCRYPTED_FILE}" \
        | awk '{print $NF}' > "${HMAC_FILE}"

    if [ ! -s "${HMAC_FILE}" ]; then
        printf 'ERROR: HMAC generation failed.\n' >&2
        rm -f "${ENCRYPTED_FILE}" "${HMAC_FILE}"
        exit 2
    fi

    rm "${FILE_NAME}"
}

decryptFile() {
    ENCRYPTED_FILE="${1}"
    if [ ! -f "${ENCRYPTED_FILE}" ]; then
        printf 'ERROR: "%s" does not exist or is not a regular file.\n' "${ENCRYPTED_FILE}" >&2
        exit 1
    fi

    HMAC_FILE="${ENCRYPTED_FILE}.hmac"
    if [ ! -f "${HMAC_FILE}" ]; then
        printf 'ERROR: integrity file "%s" not found.\n' "${HMAC_FILE}" >&2
        exit 1
    fi

    DECRYPTED_FILE="${ENCRYPTED_FILE%.${ENCRYPTED_FILE_SUFFIX}}"

    printf 'Enter passphrase: ' >&2
    stty -echo 2>/dev/null
    read PASSPHRASE
    stty echo 2>/dev/null
    printf '\n' >&2

    EXPECTED_HMAC=$(cat "${HMAC_FILE}")
    ACTUAL_HMAC=$(openssl dgst -sha512 -hmac "${PASSPHRASE}" "${ENCRYPTED_FILE}" \
        | awk '{print $NF}')

    if [ "${EXPECTED_HMAC}" != "${ACTUAL_HMAC}" ]; then
        printf 'ERROR: integrity check failed. File may be corrupted or tampered with.\n' >&2
        exit 3
    fi

    printf '%s\n' "${PASSPHRASE}" | \
        openssl enc -d -aes-256-cbc -pbkdf2 -md sha256 \
            -iter "${ENCRYPTION_ITERATIONS}" \
            -in "${ENCRYPTED_FILE}" -out "${DECRYPTED_FILE}" -pass stdin
    RESULT_CODE=${?}

    if [ "${RESULT_CODE}" -ne 0 ]; then
        printf 'ERROR: decryption failed.\n' >&2
        rm -f "${DECRYPTED_FILE}"
        exit 2
    fi

    rm "${ENCRYPTED_FILE}" "${HMAC_FILE}"
}
