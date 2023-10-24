CERT_PRIVATE_KEY_SUFFIX=priv.key
CERT_PUBLIC_KEY_SUFFIX=pub.key
CERT_REQUEST_SUFFIX=csr
CERT_SUFFIX=crt

pkiStartCA() {
    # /tank/organizations/ee/has/development/configuration/pki
    TANK_CERTS_DIR="${1}"
    # "has.ee.gintra"
    ROOT_DOMAIN=${2}

    CERT_HOST_NAME="*.${ROOT_DOMAIN}"
    TANK_CERTS_CA_DIR="${TANK_CERTS_DIR}/ca"
    CA_CERT_TIMESTAMP=$(smi-timestamp)
    CERT_ROOT_HOST_NAME=ca-${ROOT_DOMAIN}-${CA_CERT_TIMESTAMP}
    CERT_PRIVATE_KEY=${TANK_CERTS_CA_DIR}/${CERT_ROOT_HOST_NAME}.${CERT_PRIVATE_KEY_SUFFIX}
    CERT_PUBLIC_KEY=${TANK_CERTS_CA_DIR}/${CERT_ROOT_HOST_NAME}.${CERT_PUBLIC_KEY_SUFFIX}
    CERT_REQUEST=${TANK_CERTS_CA_DIR}/${CERT_ROOT_HOST_NAME}.${CERT_REQUEST_SUFFIX}
    CERT_FILE=${TANK_CERTS_CA_DIR}/${CERT_ROOT_HOST_NAME}.${CERT_SUFFIX}
    EXTENSION_FILE=$(smi-lib-location)/openssl.ca.ext.file.txt
    # Make dirs
    mkdir -p ${TANK_CERTS_CA_DIR}
    # Gen private key
    openssl genrsa -out ${CERT_PRIVATE_KEY} 2048
    # Gen public key
    openssl rsa -in ${CERT_PRIVATE_KEY} -pubout -out ${CERT_PUBLIC_KEY}
    # Gen certificate request
    openssl req -new -key ${CERT_PRIVATE_KEY} -out ${CERT_REQUEST} -subj "/C=EE/ST=Harjumaa/L=Saku/O=Hear And See Systems LLC/OU=Private Organization/CN=${CERT_HOST_NAME}/emailAddress=imre.tabur@hearandseesystems.com"
    # As CA signing CRT
    openssl x509 -req -days 2048 -in ${CERT_REQUEST} -signkey ${CERT_PRIVATE_KEY} -out ${CERT_FILE} -extfile ${EXTENSION_FILE}
    # Print out data
    openssl x509 -noout -text -in ${CERT_FILE}
}
