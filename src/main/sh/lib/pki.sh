# File-based PKI helper library.
#
# Every function communicates through files: private keys, public keys, CSRs,
# certificates and OpenSSL extension files. No key, CSR or certificate material
# is ever held in a shell variable - only file names are. Each low-level
# function wraps exactly one standardized OpenSSL operation and returns non-zero
# the moment OpenSSL fails, so a caller running under "set -e", or checking the
# return code, stops on the first error.
#
# The chain produced is:
#
#     Root CA (CA:TRUE)
#       -> Intermediate CA (CA:TRUE,pathlen:0)
#         -> Server certificate (CA:FALSE)
#
# The Root CA signs only the Intermediate CA; the Intermediate CA signs the
# routine server certificates. This suits an internal PKI where only the Root CA
# certificate is installed into trust stores (OS, Firefox, Java, containers) and
# every server certificate is then trusted through the chain.

# --------------------------------------------------------------------------
# Artifact naming - kept from the original library for compatibility.
# --------------------------------------------------------------------------
CERT_PRIVATE_KEY_SUFFIX=priv.key
CERT_PUBLIC_KEY_SUFFIX=pub.key
CERT_REQUEST_SUFFIX=csr
CERT_SUFFIX=crt
CERT_EXTENSION_SUFFIX=ext
SUBJECT_FILE=subject.sh
    # The subject file, loaded from TANK_CERTS_DIR, defines:
    # COUNTRY="EE"
    # STATE="Harjumaa"
    # LOCALITY="Saku"
    # ORG="Hear And See Systems LLC"
    # ORG_UNIT="Private Organization"
    # EMAIL="pki@example.com"

# --------------------------------------------------------------------------
# Tunables - RSA key sizes, validity, and the descriptive CA identities.
# --------------------------------------------------------------------------
# CA keys are 4096-bit by default; server keys 2048-bit. Override before calling.
CA_KEY_BITS=4096
SERVER_KEY_BITS=2048
DEFAULT_KEY_BITS=2048

# Certificate validity in days.
ROOT_CA_VALIDITY_DAYS=7300
INTERMEDIATE_CA_VALIDITY_DAYS=3650
SERVER_CERT_VALIDITY_DAYS=825

# A CA is named by its role, never by a server hostname.
ROOT_CA_COMMON_NAME="HAS Internal Root CA"
INTERMEDIATE_CA_COMMON_NAME="HAS Internal Intermediate CA"

# ==========================================================================
# Low-level key, request and signing functions. Each takes and produces files.
# ==========================================================================

# Generate an RSA private key into the output file.
# Args: OUT_KEY_FILE [BITS]   BITS defaults to DEFAULT_KEY_BITS.
pkiGeneratePrivateKey() {
    local out_key_file="${1}"
    local bits="${2:-${DEFAULT_KEY_BITS}}"
    openssl genrsa -out "${out_key_file}" "${bits}"
}

# Derive the public key of a private key into a separate file. Nothing here needs
# the public key, but the library has always kept it as its own artifact.
# Args: PRIV_KEY_FILE PUB_KEY_FILE
pkiGeneratePublicKey() {
    local priv_key_file="${1}"
    local pub_key_file="${2}"
    openssl rsa -in "${priv_key_file}" -pubout -out "${pub_key_file}"
}

# Create a certificate signing request from a private key.
# Args: PRIV_KEY_FILE CSR_FILE SUBJECT_STRING [SAN]
# When SAN is given (for example "DNS:ldap.has.ee.gintra") it is added to the
# request, so the CSR itself carries the subjectAltName.
pkiCreateCSR() {
    local priv_key_file="${1}"
    local csr_file="${2}"
    local subject_string="${3}"
    local san="${4:-}"
    if [ -n "${san}" ]; then
        openssl req -new -key "${priv_key_file}" -out "${csr_file}" \
            -subj "${subject_string}" -addext "subjectAltName=${san}"
    else
        openssl req -new -key "${priv_key_file}" -out "${csr_file}" \
            -subj "${subject_string}"
    fi
}

# Self-sign a CSR with its own private key. Used only for the Root CA.
# Args: PRIV_KEY_FILE CSR_FILE CERT_FILE DAYS EXT_FILE
pkiCreateSelfSignedCertificate() {
    local priv_key_file="${1}"
    local csr_file="${2}"
    local cert_file="${3}"
    local days="${4}"
    local ext_file="${5}"
    openssl x509 -req -in "${csr_file}" -signkey "${priv_key_file}" \
        -days "${days}" -extfile "${ext_file}" -out "${cert_file}"
}

# Sign a CSR with a CA. The CA private key is only ever read from CA_KEY_FILE;
# this function never creates or stores CA key material of its own.
# Args: CSR_FILE CA_CERT_FILE CA_KEY_FILE CERT_FILE DAYS EXT_FILE
pkiSignCSR() {
    local csr_file="${1}"
    local ca_cert_file="${2}"
    local ca_key_file="${3}"
    local cert_file="${4}"
    local days="${5}"
    local ext_file="${6}"
    openssl x509 -req -in "${csr_file}" \
        -CA "${ca_cert_file}" -CAkey "${ca_key_file}" -CAcreateserial \
        -days "${days}" -extfile "${ext_file}" -out "${cert_file}"
}

# ==========================================================================
# Extension writers. Each writes an OpenSSL extension file for one role.
# ==========================================================================

# Root CA: a CA that may sign other certificates.
pkiRootCaExtensions() {
    local out_ext_file="${1}"
    {
        echo "basicConstraints=critical,CA:TRUE"
        echo "keyUsage=critical,keyCertSign,cRLSign"
        echo "subjectKeyIdentifier=hash"
    } > "${out_ext_file}"
}

# Intermediate CA: a CA that may sign leaf certificates only (pathlen:0).
pkiIntermediateCaExtensions() {
    local out_ext_file="${1}"
    {
        echo "basicConstraints=critical,CA:TRUE,pathlen:0"
        echo "keyUsage=critical,keyCertSign,cRLSign"
        echo "subjectKeyIdentifier=hash"
        echo "authorityKeyIdentifier=keyid,issuer"
    } > "${out_ext_file}"
}

# Server (end-entity): not a CA, usable as a TLS server, identified by its SAN.
# Args: OUT_EXT_FILE SAN   for example SAN "DNS:ldap.has.ee.gintra"
pkiServerExtensions() {
    local out_ext_file="${1}"
    local san="${2}"
    {
        echo "basicConstraints=critical,CA:FALSE"
        echo "keyUsage=critical,digitalSignature,keyEncipherment"
        echo "extendedKeyUsage=serverAuth"
        echo "subjectKeyIdentifier=hash"
        echo "authorityKeyIdentifier=keyid,issuer"
        echo "subjectAltName=${san}"
    } > "${out_ext_file}"
}

# Build a /C=.../CN=... subject string for COMMON_NAME, from the C/ST/L/O/OU/EMAIL
# values the caller has already sourced from the subject file.
pkiSubjectString() {
    local common_name="${1}"
    printf '/C=%s/ST=%s/L=%s/O=%s/OU=%s/CN=%s/emailAddress=%s' \
        "${COUNTRY}" "${STATE}" "${LOCALITY}" "${ORG}" "${ORG_UNIT}" \
        "${common_name}" "${EMAIL}"
}

# ==========================================================================
# High-level orchestration. Each builds a set of artifacts from the low-level
# functions above; none runs an OpenSSL command directly.
# ==========================================================================

# Create the self-signed Root CA in TANK_CERTS_DIR/ca. Signs only Intermediate
# CAs, so its private key can then be kept offline and well protected.
# Args: TANK_CERTS_DIR ROOT_DOMAIN   ROOT_DOMAIN for example "has.ee.gintra"
pkiStartCA() {
    local tank_certs_dir="${1}"
    local root_domain="${2}"

    if [ -f "${tank_certs_dir}/${SUBJECT_FILE}" ]; then
        . "${tank_certs_dir}/${SUBJECT_FILE}"
    fi

    local ca_dir="${tank_certs_dir}/ca"
    local priv_key="${ca_dir}/${root_domain}.${CERT_PRIVATE_KEY_SUFFIX}"
    local pub_key="${ca_dir}/${root_domain}.${CERT_PUBLIC_KEY_SUFFIX}"
    local csr="${ca_dir}/${root_domain}.${CERT_REQUEST_SUFFIX}"
    local cert="${ca_dir}/${root_domain}.${CERT_SUFFIX}"
    local ext="${ca_dir}/${root_domain}.${CERT_EXTENSION_SUFFIX}"
    local subject
    subject="$(pkiSubjectString "${ROOT_CA_COMMON_NAME}")"

    mkdir -p "${ca_dir}" || return 1
    pkiGeneratePrivateKey "${priv_key}" "${CA_KEY_BITS}" || return 1
    chmod 600 "${priv_key}" || return 1
    pkiGeneratePublicKey "${priv_key}" "${pub_key}" || return 1
    pkiCreateCSR "${priv_key}" "${csr}" "${subject}" || return 1
    pkiRootCaExtensions "${ext}" || return 1
    pkiCreateSelfSignedCertificate "${priv_key}" "${csr}" "${cert}" \
        "${ROOT_CA_VALIDITY_DAYS}" "${ext}" || return 1
    openssl x509 -noout -text -in "${cert}"
}

# Create the Intermediate CA in TANK_CERTS_DIR/ca, signed by the Root CA. Never
# self-signed. Its files are named "<root-domain>.intermediate.*" so they stay
# distinct from the Root CA files in the same directory.
# Args: TANK_CERTS_DIR ROOT_DOMAIN
pkiStartIntermediateCA() {
    local tank_certs_dir="${1}"
    local root_domain="${2}"

    if [ -f "${tank_certs_dir}/${SUBJECT_FILE}" ]; then
        . "${tank_certs_dir}/${SUBJECT_FILE}"
    fi

    local ca_dir="${tank_certs_dir}/ca"
    local root_priv_key="${ca_dir}/${root_domain}.${CERT_PRIVATE_KEY_SUFFIX}"
    local root_cert="${ca_dir}/${root_domain}.${CERT_SUFFIX}"
    local int_priv_key="${ca_dir}/${root_domain}.intermediate.${CERT_PRIVATE_KEY_SUFFIX}"
    local int_pub_key="${ca_dir}/${root_domain}.intermediate.${CERT_PUBLIC_KEY_SUFFIX}"
    local int_csr="${ca_dir}/${root_domain}.intermediate.${CERT_REQUEST_SUFFIX}"
    local int_cert="${ca_dir}/${root_domain}.intermediate.${CERT_SUFFIX}"
    local int_ext="${ca_dir}/${root_domain}.intermediate.${CERT_EXTENSION_SUFFIX}"
    local subject
    subject="$(pkiSubjectString "${INTERMEDIATE_CA_COMMON_NAME}")"

    mkdir -p "${ca_dir}" || return 1
    pkiGeneratePrivateKey "${int_priv_key}" "${CA_KEY_BITS}" || return 1
    chmod 600 "${int_priv_key}" || return 1
    pkiGeneratePublicKey "${int_priv_key}" "${int_pub_key}" || return 1
    pkiCreateCSR "${int_priv_key}" "${int_csr}" "${subject}" || return 1
    pkiIntermediateCaExtensions "${int_ext}" || return 1
    pkiSignCSR "${int_csr}" "${root_cert}" "${root_priv_key}" "${int_cert}" \
        "${INTERMEDIATE_CA_VALIDITY_DAYS}" "${int_ext}" || return 1
    openssl x509 -noout -text -in "${int_cert}"
}

# Create the private key, public key and CSR for a server certificate. The CSR
# carries the requested host name in subjectAltName as DNS:<domain>, exact match,
# no wildcard.
# Args: TANK_CERTS_DIR DOMAIN_NAME   DOMAIN_NAME for example "ldap.has.ee.gintra"
pkiDoCertRequest() {
    local tank_certs_dir="${1}"
    local domain_name="${2}"

    if [ -f "${tank_certs_dir}/${SUBJECT_FILE}" ]; then
        . "${tank_certs_dir}/${SUBJECT_FILE}"
    fi

    local priv_key="${tank_certs_dir}/${domain_name}.${CERT_PRIVATE_KEY_SUFFIX}"
    local pub_key="${tank_certs_dir}/${domain_name}.${CERT_PUBLIC_KEY_SUFFIX}"
    local csr="${tank_certs_dir}/${domain_name}.${CERT_REQUEST_SUFFIX}"
    local subject
    subject="$(pkiSubjectString "${domain_name}")"

    mkdir -p "${tank_certs_dir}" || return 1
    pkiGeneratePrivateKey "${priv_key}" "${SERVER_KEY_BITS}" || return 1
    chmod 600 "${priv_key}" || return 1
    pkiGeneratePublicKey "${priv_key}" "${pub_key}" || return 1
    pkiCreateCSR "${priv_key}" "${csr}" "${subject}" "DNS:${domain_name}" || return 1
}

# Sign a server CSR with the Intermediate CA, not the Root CA. The Intermediate
# CA key and certificate are resolved from the ca directory by root domain, the
# root domain being the requested domain with its first label removed.
# Args: TANK_CERTS_DIR DOMAIN_NAME
pkiDoCASigning() {
    local tank_certs_dir="${1}"
    local domain_name="${2}"

    local root_domain="${domain_name#*.}"
    local ca_dir="${tank_certs_dir}/ca"
    local int_priv_key="${ca_dir}/${root_domain}.intermediate.${CERT_PRIVATE_KEY_SUFFIX}"
    local int_cert="${ca_dir}/${root_domain}.intermediate.${CERT_SUFFIX}"
    local csr="${tank_certs_dir}/${domain_name}.${CERT_REQUEST_SUFFIX}"
    local cert="${tank_certs_dir}/${domain_name}.${CERT_SUFFIX}"
    local ext="${tank_certs_dir}/${domain_name}.${CERT_EXTENSION_SUFFIX}"

    pkiServerExtensions "${ext}" "DNS:${domain_name}" || return 1
    pkiSignCSR "${csr}" "${int_cert}" "${int_priv_key}" "${cert}" \
        "${SERVER_CERT_VALIDITY_DAYS}" "${ext}" || return 1
    echo "${domain_name}"
    openssl x509 -noout -text -in "${cert}"
}

# Create a complete server certificate: key, public key, CSR and the certificate
# signed by the Intermediate CA.
# Args: TANK_CERTS_DIR DOMAIN_NAME
pkiCreateDomainCert() {
    local tank_certs_dir="${1}"
    local domain_name="${2}"
    pkiDoCertRequest "${tank_certs_dir}" "${domain_name}" || return 1
    pkiDoCASigning "${tank_certs_dir}" "${domain_name}" || return 1
}
