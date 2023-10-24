
ENCRYPTED_FILE_SUFFIX=enc
ENCRYPTION_ITERATIONS=10000

encryptFile() {
    FILE_NAME="${1}"
    if [ ! -f "${FILE_NAME}" ]; then
        echo "File for encryption: '${FILE_NAME}' doesn't exist."
        exit 1
    fi
    ENCRYPTED_FILE="${FILE_NAME}.${ENCRYPTED_FILE_SUFFIX}"
    openssl enc -aes-256-cbc -salt -in "${FILE_NAME}" -out "${ENCRYPTED_FILE}" -iter ${ENCRYPTION_ITERATIONS}
    RESULT_CODE=${?}

    if [ ${RESULT_CODE} -eq 0 ] && [ -s "${ENCRYPTED_FILE}" ]; then
        rm "${FILE_NAME}"
    else
        echo "Encryption failed or resulted in a 0-length file."
        exit 2
    fi
}

decryptFile() {
    ENCRYPTED_FILE="${1}"
    if [ ! -f "${ENCRYPTED_FILE}" ]; then
        echo "Encrypted file: '${ENCRYPTED_FILE}' doesn't exist."
        exit 1
    fi
    DECRYPTED_FILE="${ENCRYPTED_FILE%.${ENCRYPTED_FILE_SUFFIX}}"
    openssl enc -d -aes-256-cbc -in "${ENCRYPTED_FILE}" -out "${DECRYPTED_FILE}" -iter ${ENCRYPTION_ITERATIONS}
    RESULT_CODE=${?}
    if [ ${RESULT_CODE} -eq 0 ] && [ -s "${DECRYPTED_FILE}" ]; then
        rm "${ENCRYPTED_FILE}"
    else
        echo "Decryption failed or resulted in a 0-length file."
        exit 2
    fi
}
