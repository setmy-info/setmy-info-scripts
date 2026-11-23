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

buildPackages() {
    INSTALLABLE_PACKAGES=${*}
    for INSTALLABLE_PACKAGE in ${INSTALLABLE_PACKAGES}; do
        buildPackage ${INSTALLABLE_PACKAGE}
    done
}

installPackages() {
    INSTALLABLE_PACKAGES=${*}
    for INSTALLABLE_PACKAGE in ${INSTALLABLE_PACKAGES}; do
        installPackage ${INSTALLABLE_PACKAGE}
    done
}

# Prefix of the functions of a package: a - of the package name is _ in the function names, because sh does not
# allow - in a function name. opensearch-dashboard.package has opensearch_dashboard_install_func.
packageFunctionPrefix() {
    echo "${1}" | tr '-' '_'
}

downloadPackage() {
    PACKAGE_NAME=${1}
    PACKAGE_FUNCTION_PREFIX=$(packageFunctionPrefix ${PACKAGE_NAME})
    echo "Downloading package: ${PACKAGE_NAME}"
    includePackage ${PACKAGE_NAME}
    ${PACKAGE_FUNCTION_PREFIX}_download_func
}

buildPackage() {
    PACKAGE_NAME=${1}
    PACKAGE_FUNCTION_PREFIX=$(packageFunctionPrefix ${PACKAGE_NAME})
    includePackage ${PACKAGE_NAME}
    if command -v ${PACKAGE_FUNCTION_PREFIX}_build_func > /dev/null 2>&1; then
        echo "Building package: ${PACKAGE_NAME}"
        ${PACKAGE_FUNCTION_PREFIX}_build_func
    else
        echo "Nothing to build for package: ${PACKAGE_NAME}"
    fi
}

installPackage() {
    PACKAGE_NAME=${1}
    PACKAGE_FUNCTION_PREFIX=$(packageFunctionPrefix ${PACKAGE_NAME})
    echo "Installing package: ${PACKAGE_NAME}"
    includePackage ${PACKAGE_NAME}
    ${PACKAGE_FUNCTION_PREFIX}_install_func
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
