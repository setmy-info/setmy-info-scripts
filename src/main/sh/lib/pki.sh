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
CERT_PKCS12_SUFFIX=p12
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
CLIENT_CERT_VALIDITY_DAYS=365

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

# Bundle a private key and its certificate into a PKCS#12 file, the single file
# format browsers, Java keystores and many clients import. CA_CERT_FILE, when given,
# is added to the bundle as the chain, so the client also presents the Intermediate CA.
# The export password is read from SMI_PKI_PKCS12_PASSWORD when it is set, never from
# the command line where the process list would show it; without the variable OpenSSL
# asks for it on the terminal.
# Args: PRIV_KEY_FILE CERT_FILE P12_FILE FRIENDLY_NAME [CA_CERT_FILE]
pkiExportPkcs12() {
    local priv_key_file="${1}"
    local cert_file="${2}"
    local p12_file="${3}"
    local friendly_name="${4}"
    local ca_cert_file="${5:-}"

    set -- -export -inkey "${priv_key_file}" -in "${cert_file}" \
        -out "${p12_file}" -name "${friendly_name}"
    if [ -n "${ca_cert_file}" ]; then
        set -- "$@" -certfile "${ca_cert_file}"
    fi
    if [ -n "${SMI_PKI_PKCS12_PASSWORD:-}" ]; then
        set -- "$@" -passout env:SMI_PKI_PKCS12_PASSWORD
    fi

    openssl pkcs12 "$@" || return 1
    chmod 600 "${p12_file}"
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

# Client (end-entity): not a CA, usable only to authenticate a TLS client (mTLS).
# digitalSignature alone, because a TLS client only signs the handshake; that
# also holds for EC keys, where keyEncipherment would be wrong.
# Args: OUT_EXT_FILE
pkiClientExtensions() {
    local out_ext_file="${1}"
    {
        echo "basicConstraints=critical,CA:FALSE"
        echo "keyUsage=critical,digitalSignature"
        echo "extendedKeyUsage=clientAuth"
        echo "subjectKeyIdentifier=hash"
        echo "authorityKeyIdentifier=keyid,issuer"
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

# Print the root domain the CA files are named by: ROOT_DOMAIN when given, otherwise
# DOMAIN_NAME with its first label removed ("ldap.has.ee.gintra" -> "has.ee.gintra").
# Args: DOMAIN_NAME [ROOT_DOMAIN]
pkiRootDomain() {
    local domain_name="${1}"
    local root_domain="${2:-}"

    if [ -n "${root_domain}" ]; then
        printf '%s' "${root_domain}"
    else
        printf '%s' "${domain_name#*.}"
    fi
}

# Fail with a message naming the missing file unless the Intermediate CA key and
# certificate of ROOT_DOMAIN exist in TANK_CERTS_DIR/ca.
# Args: TANK_CERTS_DIR ROOT_DOMAIN
pkiRequireIntermediateCA() {
    local tank_certs_dir="${1}"
    local root_domain="${2}"

    local ca_file
    for ca_file in \
        "${tank_certs_dir}/ca/${root_domain}.intermediate.${CERT_PRIVATE_KEY_SUFFIX}" \
        "${tank_certs_dir}/ca/${root_domain}.intermediate.${CERT_SUFFIX}"; do
        if [ ! -f "${ca_file}" ]; then
            echo "Intermediate CA of root domain '${root_domain}' not found: ${ca_file}" >&2
            echo "Give the root domain the CA was created with, or create it with smi-pki-start-intermediate-ca" >&2
            return 1
        fi
    done
}

# Sign a server CSR with the Intermediate CA, not the Root CA. The Intermediate
# CA key and certificate are resolved from the ca directory by root domain, see
# pkiRootDomain.
# Args: TANK_CERTS_DIR DOMAIN_NAME [ROOT_DOMAIN]
pkiDoCASigning() {
    local tank_certs_dir="${1}"
    local domain_name="${2}"

    local root_domain
    root_domain="$(pkiRootDomain "${domain_name}" "${3:-}")"
    local ca_dir="${tank_certs_dir}/ca"
    local int_priv_key="${ca_dir}/${root_domain}.intermediate.${CERT_PRIVATE_KEY_SUFFIX}"
    local int_cert="${ca_dir}/${root_domain}.intermediate.${CERT_SUFFIX}"
    local csr="${tank_certs_dir}/${domain_name}.${CERT_REQUEST_SUFFIX}"
    local cert="${tank_certs_dir}/${domain_name}.${CERT_SUFFIX}"
    local ext="${tank_certs_dir}/${domain_name}.${CERT_EXTENSION_SUFFIX}"

    pkiRequireIntermediateCA "${tank_certs_dir}" "${root_domain}" || return 1
    pkiServerExtensions "${ext}" "DNS:${domain_name}" || return 1
    pkiSignCSR "${csr}" "${int_cert}" "${int_priv_key}" "${cert}" \
        "${SERVER_CERT_VALIDITY_DAYS}" "${ext}" || return 1
    echo "${domain_name}"
    openssl x509 -noout -text -in "${cert}"
}

# Create a complete server certificate: key, public key, CSR and the certificate
# signed by the Intermediate CA. The Intermediate CA is checked before any server
# key is generated, so a wrong root domain leaves no half made files behind.
# Args: TANK_CERTS_DIR DOMAIN_NAME [ROOT_DOMAIN]
pkiCreateDomainCert() {
    local tank_certs_dir="${1}"
    local domain_name="${2}"
    local root_domain
    root_domain="$(pkiRootDomain "${domain_name}" "${3:-}")"

    pkiRequireIntermediateCA "${tank_certs_dir}" "${root_domain}" || return 1
    pkiDoCertRequest "${tank_certs_dir}" "${domain_name}" || return 1
    pkiDoCASigning "${tank_certs_dir}" "${domain_name}" "${root_domain}" || return 1
}

# ==========================================================================
# Client certificates for mutual TLS. The client creates its key and request
# with pkiDoClientCertRequest and sends only the CSR; the CA side checks it with
# pkiVerifyClientCSR and signs it with pkiDoClientSigning. Client files are named
# "<client-name>.client.*", so they never collide with server files.
# ==========================================================================

# Create the private key, public key and CSR of a client certificate, with
# CLIENT_NAME as Common Name. Run on the client side: the private key stays there.
# Args: TANK_CERTS_DIR CLIENT_NAME   CLIENT_NAME for example "acme-billing"
pkiDoClientCertRequest() {
    local tank_certs_dir="${1}"
    local client_name="${2}"

    if [ -f "${tank_certs_dir}/${SUBJECT_FILE}" ]; then
        . "${tank_certs_dir}/${SUBJECT_FILE}"
    fi

    local priv_key="${tank_certs_dir}/${client_name}.client.${CERT_PRIVATE_KEY_SUFFIX}"
    local pub_key="${tank_certs_dir}/${client_name}.client.${CERT_PUBLIC_KEY_SUFFIX}"
    local csr="${tank_certs_dir}/${client_name}.client.${CERT_REQUEST_SUFFIX}"
    local subject
    subject="$(pkiSubjectString "${client_name}")"

    mkdir -p "${tank_certs_dir}" || return 1
    pkiGeneratePrivateKey "${priv_key}" "${SERVER_KEY_BITS}" || return 1
    chmod 600 "${priv_key}" || return 1
    pkiGeneratePublicKey "${priv_key}" "${pub_key}" || return 1
    pkiCreateCSR "${priv_key}" "${csr}" "${subject}" || return 1
}

# Check a received client CSR before it is signed: its self-signature must be valid
# (the sender holds the private key) and its only Common Name must be exactly
# CLIENT_NAME, the identity the CA agreed to, so a client cannot name itself as
# another client. Extensions the CSR asks for are never used: pkiSignCSR takes
# them only from the extension file.
# Args: CSR_FILE CLIENT_NAME
pkiVerifyClientCSR() {
    local csr_file="${1}"
    local client_name="${2}"
    local common_name

    openssl req -in "${csr_file}" -noout -verify || return 1
    common_name="$(openssl req -in "${csr_file}" -noout -subject -nameopt multiline \
        | sed -n 's/^ *commonName *= //p')" || return 1
    if [ "${common_name}" != "${client_name}" ]; then
        echo "Client CSR ${csr_file} has Common Name '${common_name}', expected '${client_name}'" >&2
        return 1
    fi
    openssl req -in "${csr_file}" -noout -subject
}

# Sign a received client CSR "<client-name>.client.csr" in TANK_CERTS_DIR with the
# Intermediate CA of ROOT_DOMAIN. Writes the certificate and a chain file, the
# certificate followed by the Intermediate CA certificate, to send back.
# Args: TANK_CERTS_DIR CLIENT_NAME ROOT_DOMAIN
pkiDoClientSigning() {
    local tank_certs_dir="${1}"
    local client_name="${2}"
    local root_domain="${3}"

    local ca_dir="${tank_certs_dir}/ca"
    local int_priv_key="${ca_dir}/${root_domain}.intermediate.${CERT_PRIVATE_KEY_SUFFIX}"
    local int_cert="${ca_dir}/${root_domain}.intermediate.${CERT_SUFFIX}"
    local csr="${tank_certs_dir}/${client_name}.client.${CERT_REQUEST_SUFFIX}"
    local cert="${tank_certs_dir}/${client_name}.client.${CERT_SUFFIX}"
    local chain="${tank_certs_dir}/${client_name}.client.chain.${CERT_SUFFIX}"
    local ext="${tank_certs_dir}/${client_name}.client.${CERT_EXTENSION_SUFFIX}"

    pkiRequireIntermediateCA "${tank_certs_dir}" "${root_domain}" || return 1
    pkiVerifyClientCSR "${csr}" "${client_name}" || return 1
    pkiClientExtensions "${ext}" || return 1
    pkiSignCSR "${csr}" "${int_cert}" "${int_priv_key}" "${cert}" \
        "${CLIENT_CERT_VALIDITY_DAYS}" "${ext}" || return 1
    cat "${cert}" "${int_cert}" > "${chain}" || return 1
    openssl x509 -noout -text -in "${cert}"
}

# Bundle an issued client certificate, its private key and the Intermediate CA of
# ROOT_DOMAIN into <client-name>.client.p12, for a client that imports one file.
# Args: TANK_CERTS_DIR CLIENT_NAME ROOT_DOMAIN
pkiExportClientPkcs12() {
    local tank_certs_dir="${1}"
    local client_name="${2}"
    local root_domain="${3}"

    local priv_key="${tank_certs_dir}/${client_name}.client.${CERT_PRIVATE_KEY_SUFFIX}"
    local cert="${tank_certs_dir}/${client_name}.client.${CERT_SUFFIX}"
    local int_cert="${tank_certs_dir}/ca/${root_domain}.intermediate.${CERT_SUFFIX}"
    local p12="${tank_certs_dir}/${client_name}.client.${CERT_PKCS12_SUFFIX}"

    pkiExportPkcs12 "${priv_key}" "${cert}" "${p12}" "${client_name}" "${int_cert}"
}

# Create a complete client certificate on the CA side, for a client that does not
# create its own key: key, public key, CSR, certificate, chain file and PKCS#12
# bundle. The client needs only the .client.p12 file and its password.
# Args: TANK_CERTS_DIR CLIENT_NAME ROOT_DOMAIN
pkiCreateClientCert() {
    local tank_certs_dir="${1}"
    local client_name="${2}"
    local root_domain="${3}"

    pkiRequireIntermediateCA "${tank_certs_dir}" "${root_domain}" || return 1
    pkiDoClientCertRequest "${tank_certs_dir}" "${client_name}" || return 1
    pkiDoClientSigning "${tank_certs_dir}" "${client_name}" "${root_domain}" || return 1
    pkiExportClientPkcs12 "${tank_certs_dir}" "${client_name}" "${root_domain}" || return 1
}
