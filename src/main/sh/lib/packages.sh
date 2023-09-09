PACKAGE_SUFFIX="package"
SYSTEM_PACKAGES_DIR=$(smi-lib-location)/packages
PROVIDER_HOME_DIR=~/.${PROVIDER}
HOME_PACKAGES_DIR=${PROVIDER_HOME_DIR}/packages

createHomePackagesFolder() {
    mkdir -p ${HOME_PACKAGES_DIR}
}

loadPackages() {
    INSTALLABLE_PACKAGES=${*}
    PACKAGES=
    for INSTALLABLE_PACKAGE in ${INSTALLABLE_PACKAGES}; do
        HOME_PACKAGE_FILE_NAME="${HOME_PACKAGES_DIR}/${INSTALLABLE_PACKAGE}.${PACKAGE_SUFFIX}"
        SYSTEM_PROFILE_FILE_NAME="${SYSTEM_PACKAGES_DIR}/${INSTALLABLE_PACKAGE}.${PACKAGE_SUFFIX}"
        if [ -f "${HOME_PACKAGE_FILE_NAME}" ]; then
            echo "Loading: ${HOME_PACKAGE_FILE_NAME}"
            . ${HOME_PACKAGE_FILE_NAME}
            # TODO : single package info (url, dest, name, ...)
            #loadPackages ${PACKAGES}
        elif [ -f "${SYSTEM_PROFILE_FILE_NAME}" ]; then
            echo "Loading: ${SYSTEM_PROFILE_FILE_NAME}"
            . ${SYSTEM_PROFILE_FILE_NAME}
            #loadPackages ${PACKAGES}
        fi
    done
    return
}

installPackages() {
    INSTALLABLE_PACKAGES=${*}
    return
}