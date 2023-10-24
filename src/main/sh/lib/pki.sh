CERT_PRIVATE_KEY_SUFFIX=priv.key
CERT_PUBLIC_KEY_SUFFIX=pub.key
CERT_REQUEST_SUFFIX=csr
CERT_SUFFIX=crt
SUBJECT_FILE=subject.sh
    # COUNTRY="EE"
    # STATE="Harjumaa"
    # LOCALITY="Saku"
    # ORG="Hear And See Systems LLC"
    # ORG_UNIT="Private Organization"
    # EMAIL="imre.tabur@hearandseesystems.com"


pkiStartCA() {
    # /tank/organizations/ee/has/development/configuration/pki
    TANK_CERTS_DIR="${1}"
    # "has.ee.gintra"
    ROOT_DOMAIN=${2}

    if [ -f "${TANK_CERTS_DIR}/${SUBJECT_FILE}" ]; then
        . "${TANK_CERTS_DIR}/${SUBJECT_FILE}"
    fi

    CERT_HOST_NAME="*.${ROOT_DOMAIN}"
    TANK_CERTS_CA_DIR="${TANK_CERTS_DIR}/ca"
    CERT_PRIVATE_KEY=${TANK_CERTS_CA_DIR}/${ROOT_DOMAIN}.${CERT_PRIVATE_KEY_SUFFIX}
    CERT_PUBLIC_KEY=${TANK_CERTS_CA_DIR}/${ROOT_DOMAIN}.${CERT_PUBLIC_KEY_SUFFIX}
    CERT_REQUEST=${TANK_CERTS_CA_DIR}/${ROOT_DOMAIN}.${CERT_REQUEST_SUFFIX}
    CERT_FILE=${TANK_CERTS_CA_DIR}/${ROOT_DOMAIN}.${CERT_SUFFIX}
    EXTENSION_FILE=$(smi-lib-location)/openssl.ca.ext.file.txt
    SUBJECT_STRING="/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORG}/OU=${ORG_UNIT}/CN=${CERT_HOST_NAME}/emailAddress=${EMAIL}"
    # Make dirs
    mkdir -p ${TANK_CERTS_CA_DIR}
    # Gen private key
    openssl genrsa -out ${CERT_PRIVATE_KEY} 2048
    # Gen public key
    openssl rsa -in ${CERT_PRIVATE_KEY} -pubout -out ${CERT_PUBLIC_KEY}
    # Gen certificate request
    openssl req -new -key ${CERT_PRIVATE_KEY} -out ${CERT_REQUEST} -subj "${SUBJECT_STRING}"
    # As CA signing CRT
    openssl x509 -req -days 2048 -in ${CERT_REQUEST} -signkey ${CERT_PRIVATE_KEY} -out ${CERT_FILE} -extfile ${EXTENSION_FILE}
    # Print out data
    openssl x509 -noout -text -in ${CERT_FILE}
}

pkiDoCertRequest() {
    # /tank/organizations/ee/has/development/configuration/pki
    TANK_CERTS_DIR="${1}"
    # "ldap.has.ee.gintra"
    DOMAIN_NAME=${2}

    if [ -f "${TANK_CERTS_DIR}/${SUBJECT_FILE}" ]; then
        . "${TANK_CERTS_DIR}/${SUBJECT_FILE}"
    fi

    CERT_PRIVATE_KEY=${TANK_CERTS_DIR}/${DOMAIN_NAME}.${CERT_PRIVATE_KEY_SUFFIX}
    CERT_PUBLIC_KEY=${TANK_CERTS_DIR}/${DOMAIN_NAME}.${CERT_PUBLIC_KEY_SUFFIX}
    CERT_REQUEST=${TANK_CERTS_DIR}/${DOMAIN_NAME}.${CERT_REQUEST_SUFFIX}
    CERT_FILE=${TANK_CERTS_DIR}/${DOMAIN_NAME}.${CERT_SUFFIX}
    SUBJECT_STRING="/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORG}/OU=${ORG_UNIT}/CN=${DOMAIN_NAME}/emailAddress=${EMAIL}"
    # Make dirs
    mkdir -p ${TANK_CERTS_DIR}
    # Gen private key
    openssl genrsa -out ${CERT_PRIVATE_KEY} 2048
    # Gen public key
    openssl rsa -in ${CERT_PRIVATE_KEY} -pubout -out ${CERT_PUBLIC_KEY}
    # Gen certificate request
    openssl req -new -key ${CERT_PRIVATE_KEY} -out ${CERT_REQUEST} -subj "${SUBJECT_STRING}"
}

pkiDoCASigning() {
    # /tank/organizations/ee/has/development/configuration/pki
    TANK_CERTS_DIR="${1}"
    # "ldap.has.ee.gintra"
    DOMAIN_NAME=${2}

    # "has.ee.gintra"
    ROOT_DOMAIN=${DOMAIN_NAME#*.}
    TANK_CERTS_CA_DIR="${TANK_CERTS_DIR}/ca"
    CA_CERT_PRIVATE_KEY=${TANK_CERTS_CA_DIR}/${ROOT_DOMAIN}.${CERT_PRIVATE_KEY_SUFFIX}
    CA_CERT=${TANK_CERTS_CA_DIR}/${ROOT_DOMAIN}.${CERT_SUFFIX}
    CERT_REQUEST=${TANK_CERTS_DIR}/${DOMAIN_NAME}.${CERT_REQUEST_SUFFIX}
    CERT_FILE=${TANK_CERTS_DIR}/${DOMAIN_NAME}.${CERT_SUFFIX}

    openssl x509 -req -days 1095 \
        -in ${CERT_REQUEST} \
        -CA ${CA_CERT} \
        -CAkey ${CA_CERT_PRIVATE_KEY} \
        -CAcreateserial -out ${CERT_FILE}
    echo ${DOMAIN_NAME}
    openssl x509 -noout -text -in ${CERT_FILE}
}

pkiCreateDomainCert() {
    # /tank/organizations/ee/has/development/configuration/pki
    TANK_CERTS_DIR="${1}"
    # "ldap.has.ee.gintra"
    DOMAIN_NAME=${2}
    pkiDoCertRequest ${TANK_CERTS_DIR} ${DOMAIN_NAME}
    pkiDoCASigning   ${TANK_CERTS_DIR} ${DOMAIN_NAME}
}
