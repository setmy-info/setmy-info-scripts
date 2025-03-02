SYSTEM_PACKAGES_DIR=$(smi-packages-location)
HOME_PACKAGES_DIR=$(smi-home-packages-location)
PACKAGE_SUFFIX=package

createHomePackagesFolder() {
    mkdir -p ${HOME_PACKAGES_DIR}
}

downloadPackages() {
    INSTALLABLE_PACKAGES=${*}
    for INSTALLABLE_PACKAGE in ${INSTALLABLE_PACKAGES}; do
        downloadPackage ${INSTALLABLE_PACKAGE}
    done
}

installPackages() {
    INSTALLABLE_PACKAGES=${*}
    for INSTALLABLE_PACKAGE in ${INSTALLABLE_PACKAGES}; do
        installPackage ${INSTALLABLE_PACKAGE}
    done
}

downloadPackage() {
    PACKAGE_NAME=${1}
    echo "Downloading package: ${PACKAGE_NAME}"
    includePackage ${PACKAGE_NAME}
    ${PACKAGE_NAME}_download_func
}

installPackage() {
    PACKAGE_NAME=${1}
    echo "Installing package: ${PACKAGE_NAME}"
    includePackage ${PACKAGE_NAME}
    ${PACKAGE_NAME}_install_func
}

includePackages() {
    INCLUDE_PACKAGES=${*}
    for PACKAGE_NAME in ${INCLUDE_PACKAGES}; do
        includePackage ${PACKAGE_NAME}
    done
}

includePackage() {
    PACKAGE_NAME=${1}
    SYS_PACKAGE_FILE_NAME=${SYSTEM_PACKAGES_DIR}/${PACKAGE_NAME}.${PACKAGE_SUFFIX}
    HOME_PACKAGE_FILE_NAME=${HOME_PACKAGES_DIR}/${PACKAGE_NAME}.${PACKAGE_SUFFIX}
    if [ -f "${SYS_PACKAGE_FILE_NAME}" ]; then
        . ${SYS_PACKAGE_FILE_NAME}
    fi
    if [ -f "${HOME_PACKAGE_FILE_NAME}" ]; then
        . ${HOME_PACKAGE_FILE_NAME}
    fi
}

makeOptLink() {
    PACKAGE_OPT_LINK=${1}
    PACKAGE_OPT_DIR=${2}
    sudo rm -f  ${PACKAGE_OPT_LINK}
    sudo ln -sf ${PACKAGE_OPT_DIR} ${PACKAGE_OPT_LINK}
}
