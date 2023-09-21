SYSTEM_PACKAGES_DIR=$(smi-packages-location)
HOME_PACKAGES_DIR=$(smi-home-packages-location)
PACKAGE_PREFIX=package

JDK_NAME=jdk
JDK_VERSION=21
JDK_HASH=fd2272bbf8e04c3dbaee13770090416c
JDK_URI_NR_PART=35
JDK_DIR_NAME=jdk-${JDK_VERSION}
JDK_NAME_PREFIX=openjdk-${JDK_VERSION}
JDK_TAR_FILE_NAME=${JDK_NAME_PREFIX}_linux-x64_bin.tar
JDK_TAR_GZ_FILE_NAME=${JDK_TAR_FILE_NAME}.gz
JDK_TAR_GZ_FILE_URL=https://download.java.net/java/GA/jdk${JDK_VERSION}/${JDK_HASH}/${JDK_URI_NR_PART}/GPL/${JDK_TAR_GZ_FILE_NAME}
jdk_download_func() {
    smi-download ${JDK_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${JDK_TAR_GZ_FILE_NAME}
}
jdk_install_func() {
    sudo tar --overwrite -xvzf ${HOME_PACKAGES_DIR}/${JDK_TAR_GZ_FILE_NAME} -C /opt
    sudo ln -sf /opt/${JDK_DIR_NAME} /opt/jdk
}

ZULU_NAME=zulu
ZULU_JDK17_VERSION=17.44.15
ZULU_JDK17_BASE_VERSION=17.0.8
ZULU_JDK17_DIR_NAME=zulu${ZULU_JDK17_VERSION}-ca-jdk${ZULU_JDK17_BASE_VERSION}-linux_x64
ZULU_JDK17_NAME_PREFIX=zulu${ZULU_JDK17_VERSION}-ca-jdk${ZULU_JDK17_BASE_VERSION}
ZULU_JDK17_ZIP_FILE_NAME=${ZULU_JDK17_NAME_PREFIX}-linux_x64.zip
ZULU_JDK17_TAR_GZ_FILE_URL=https://cdn.azul.com/zulu/bin/${ZULU_JDK17_ZIP_FILE_NAME}
zulu_jdk_download_func() {
    smi-download ${ZULU_JDK17_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${ZULU_JDK17_ZIP_FILE_NAME}
}
zulu_jdk_install_func() {
    sudo unzip -o ${HOME_PACKAGES_DIR}/${ZULU_JDK17_ZIP_FILE_NAME} -d /opt
    sudo ln -sf /opt/${ZULU_JDK17_DIR_NAME} /opt/zulu-jdk17
}

JDK17_NAME=jdk17
JDK17_VERSION=17.0.2
JDK17_HASH_PART=dfd4a8d0985749f896bed50d7138ee7f
JDK17_NUMERIC_PART=8
JDK17_DIR_NAME=jdk-${JDK17_VERSION}
JDK17_NAME_PREFIX=openjdk-${JDK17_VERSION}
JDK17_TAR_FILE_NAME=${JDK17_NAME_PREFIX}_linux-x64_bin.tar
JDK17_TAR_GZ_FILE_NAME=${JDK17_TAR_FILE_NAME}.gz
JDK17_TAR_GZ_FILE_URL=https://download.java.net/java/GA/jdk${JDK17_VERSION}/${JDK17_HASH_PART}/${JDK17_NUMERIC_PART}/GPL/${JDK17_TAR_GZ_FILE_NAME}
jdk17_download_func() {
    smi-download ${JDK17_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${JDK17_TAR_GZ_FILE_NAME}
}
jdk17_install_func() {
    sudo tar --overwrite -xvzf ${HOME_PACKAGES_DIR}/${JDK17_TAR_GZ_FILE_NAME} -C /opt
    sudo ln -sf /opt/${JDK17_DIR_NAME} /opt/jdk17
}

INFINISPAN_NAME=infinispan
INFINISPAN_VERSION=14.0.13
INFINISPAN_DIR_NAME=infinispan-server-${INFINISPAN_VERSION}.Final
INFINISPAN_ZIP_FILE_NAME=${INFINISPAN_DIR_NAME}.zip
INFINISPAN_ZIP_FILE_URL=https://downloads.jboss.org/infinispan/${INFINISPAN_VERSION}.Final/${INFINISPAN_ZIP_FILE_NAME}
infinispan_download_func() {
    smi-download ${INFINISPAN_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${INFINISPAN_ZIP_FILE_NAME}
}
infinispan_install_func() {
    sudo unzip -o ${HOME_PACKAGES_DIR}/${INFINISPAN_ZIP_FILE_NAME} -d /opt
    sudo ln -sf /opt/${INFINISPAN_DIR_NAME} /opt/infinispan
}

HSQLDB_NAME=hsqldb
HSQLDB_VERSION=2.7.2
HSQLDB_DIR_NAME=hsqldb-${HSQLDB_VERSION}
HSQLDB_ZIP_FILE_NAME=${HSQLDB_DIR_NAME}.zip
HSQLDB_ZIP_FILE_URL=https://altushost-swe.dl.sourceforge.net/project/hsqldb/hsqldb/hsqldb_2_7/${HSQLDB_ZIP_FILE_NAME}
hsqldb_download_func() {
    smi-download ${HSQLDB_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${HSQLDB_ZIP_FILE_NAME}
}
hsqldb_install_func() {
    sudo unzip -o ${HOME_PACKAGES_DIR}/${HSQLDB_ZIP_FILE_NAME} -d /opt
    sudo ln -sf /opt/${HSQLDB_DIR_NAME} /opt/hsqldb
}

NODE_NAME=node
NODE_VERSION=18.17.1
NODE_DIR_NAME=node-v${NODE_VERSION}-linux-x64
NODE_TAR_FILE_NAME=${NODE_DIR_NAME}.tar
NODE_TAR_XZ_FILE_NAME=${NODE_TAR_FILE_NAME}.xz
NODE_TAR_XZ_FILE_URL=https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TAR_XZ_FILE_NAME}
nodejs_download_func() {
    smi-download ${NODE_TAR_XZ_FILE_URL} ${HOME_PACKAGES_DIR}/${NODE_TAR_XZ_FILE_NAME}
}
nodejs_install_func() {
    sudo tar --overwrite -xvJf ${HOME_PACKAGES_DIR}/${NODE_TAR_XZ_FILE_NAME} -C /opt
    sudo ln -sf /opt/${NODE_DIR_NAME} /opt/node
}

MAVEN_NAME=maven
MAVEN_VERSION=3.9.4
MAVEN_DIR_NAME=apache-maven-${MAVEN_VERSION}
MAVEN_TAR_FILE_NAME=${MAVEN_DIR_NAME}-bin.tar
MAVEN_TAR_GZ_FILE_NAME=${MAVEN_TAR_FILE_NAME}.gz
MAVEN_TAR_GZ_FILE_URL=https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
maven_download_func() {
    smi-download ${MAVEN_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${MAVEN_TAR_GZ_FILE_NAME}
}
maven_install_func() {
    sudo tar --overwrite -xvzf ${HOME_PACKAGES_DIR}/${MAVEN_TAR_GZ_FILE_NAME} -C /opt
    sudo ln -sf /opt/${MAVEN_DIR_NAME} /opt/maven
}

GRADLE_NAME=gradle
GRADLE_VERSION=8.3
GRADLE_DIR_NAME=gradle-${GRADLE_VERSION}
GRADLE_ZIP_FILE_NAME=${GRADLE_DIR_NAME}-bin.zip
GRADLE_ZIP_FILE_URL=https://services.gradle.org/distributions/${GRADLE_ZIP_FILE_NAME}
gradle_download_func() {
    smi-download ${GRADLE_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${GRADLE_ZIP_FILE_NAME}
}
gradle_install_func() {
    sudo unzip -o ${HOME_PACKAGES_DIR}/${GRADLE_ZIP_FILE_NAME} -d /opt
    sudo ln -sf /opt/${GRADLE_DIR_NAME} /opt/gradle
}

CMAKE_NAME=cmake
CMAKE_VERSION=3.27.4
CMAKE_DIR_NAME=cmake-${CMAKE_VERSION}-linux-x86_64
CMAKE_TAR_FILE_NAME=${CMAKE_DIR_NAME}.tar
CMAKE_TAR_GZ_FILE_NAME=${CMAKE_TAR_FILE_NAME}.gz
CMAKE_TAR_GZ_FILE_URL=https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_TAR_GZ_FILE_NAME}
cmake_download_func() {
    smi-download ${CMAKE_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${CMAKE_TAR_GZ_FILE_NAME}
}
cmake_install_func() {
    sudo tar --overwrite -xvzf ${HOME_PACKAGES_DIR}/${CMAKE_TAR_GZ_FILE_NAME} -C /opt
    sudo ln -sf /opt/${CMAKE_DIR_NAME} /opt/cmake
}

JULIA_NAME=julia
JULIA_BASE_VERSION=1.9
JULIA_VERSION=${JULIA_BASE_VERSION}.3
JULIA_DIR_NAME=${JULIA_NAME}-${JULIA_VERSION}
JULIA_TAR_FILE_NAME=${JULIA_DIR_NAME}-linux-x86_64.tar
JULIA_TAR_GZ_FILE_NAME=${JULIA_TAR_FILE_NAME}.gz
JULIA_TAR_GZ_FILE_URL=https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_BASE_VERSION}/${JULIA_TAR_GZ_FILE_NAME}
julia_download_func() {
    smi-download ${JULIA_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${JULIA_TAR_GZ_FILE_NAME}
}
julia_install_func() {
    sudo tar --overwrite -xvzf ${HOME_PACKAGES_DIR}/${JULIA_TAR_GZ_FILE_NAME} -C /opt
    sudo rm -f /opt/${JULIA_NAME}
    sudo ln -sf /opt/${JULIA_DIR_NAME} /opt/${JULIA_NAME}
}

GO_NAME=go
GO_VERSION=1.21.1
GO_DIR_NAME=${GO_NAME}
GO_TAR_FILE_NAME=${GO_DIR_NAME}${GO_VERSION}.linux-amd64.tar
GO_TAR_GZ_FILE_NAME=${GO_TAR_FILE_NAME}.gz
GO_TAR_GZ_FILE_URL=https://go.dev/dl/${GO_TAR_GZ_FILE_NAME}
go_download_func() {
    smi-download ${GO_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${GO_TAR_GZ_FILE_NAME}
}
go_install_func() {
    sudo tar --overwrite -xvzf ${HOME_PACKAGES_DIR}/${GO_TAR_GZ_FILE_NAME} -C /opt
    sudo ln -sf /opt/${GO_DIR_NAME} /opt/go
}

DVC_NAME=dvc
DVC_VERSION=3.19.0
DVC_DIR_NAME=dvc-${DVC_VERSION}-1.x86_64
DVC_RPM_FILE_NAME=${DVC_DIR_NAME}.rpm
DVC_RPM_FILE_URL=https://s3-us-east-2.amazonaws.com/dvc-s3-repo/rpm/${DVC_RPM_FILE_NAME}
dvc_download_func() {
    smi-download ${DVC_RPM_FILE_URL} ${HOME_PACKAGES_DIR}/${DVC_RPM_FILE_NAME}
}
dvc_install_func() {
    sudo rpm -Uvh ${HOME_PACKAGES_DIR}/${DVC_RPM_FILE_NAME}
}

JENKINS_NAME=jenkins
JENKINS_VERSION=2.423
JENKINS_DIR_NAME=jenkins
JENKINS_WAR_FILE_NAME=${JENKINS_DIR_NAME}.war
#JENKINS_WAR_FILE_URL=https://ftp.halifax.rwth-aachen.de/jenkins/war-stable/${JENKINS_VERSION}/${JENKINS_WAR_FILE_NAME}
JENKINS_WAR_FILE_URL=https://ftp.halifax.rwth-aachen.de/jenkins/war/${JENKINS_VERSION}/${JENKINS_WAR_FILE_NAME}
jenkins_download_func() {
    smi-download ${JENKINS_WAR_FILE_URL} ${HOME_PACKAGES_DIR}/${JENKINS_WAR_FILE_NAME}
}
jenkins_install_func() {
    return
}

GROOVY_NAME=groovy
GROOVY_VERSION=4.0.14
GROOVY_DIR_NAME=apache-groovy-sdk-${GROOVY_VERSION}
GROOVY_ZIP_FILE_NAME=${GROOVY_DIR_NAME}.zip
GROOVY_ZIP_FILE_URL="https://groovy.jfrog.io/ui/api/v1/download?repoKey=dist-release-local&path=groovy-zips%252F${GROOVY_ZIP_FILE_NAME}&isNativeBrowsing=true"
groovy_download_func() {
    smi-download ${GROOVY_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${GROOVY_ZIP_FILE_NAME}
}
groovy_install_func() {
    sudo unzip -o ${HOME_PACKAGES_DIR}/${GROOVY_ZIP_FILE_NAME} -d /opt
    sudo ln -sf /opt/${GROOVY_DIR_NAME} /opt/groovy
}

MN_NAME=micronaut
MN_VERSION=4.1.0
MN_DIR_NAME=micronaut-cli-${MN_VERSION}
MN_ZIP_FILE_NAME=${MN_DIR_NAME}.zip
MN_ZIP_FILE_URL=https://github.com/micronaut-projects/micronaut-starter/releases/download/v${MN_VERSION}/${MN_ZIP_FILE_NAME}
mn_download_func() {
    smi-download ${MN_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${MN_ZIP_FILE_NAME}
}
mn_install_func() {
    sudo unzip -o ${HOME_PACKAGES_DIR}/${MN_ZIP_FILE_NAME} -d /opt
    sudo rm -f /opt/micronaut
    sudo rm -f /opt/mn
    sudo ln -sf /opt/${MN_DIR_NAME} /opt/micronaut
    sudo ln -sf /opt/${MN_DIR_NAME} /opt/mn
}

GRAILS_NAME=grails
GRAILS_VERSION=6.0.0
GRAILS_DIR_NAME=${GRAILS_NAME}-${GRAILS_VERSION}
GRAILS_ZIP_FILE_NAME=${GRAILS_DIR_NAME}.zip
GRAILS_ZIP_FILE_URL=https://github.com/grails/grails-core/releases/download/v${GRAILS_VERSION}/${GRAILS_ZIP_FILE_NAME}
grails_download_func() {
    smi-download ${GRAILS_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${GRAILS_ZIP_FILE_NAME}
}
grails_install_func() {
    sudo unzip -o ${HOME_PACKAGES_DIR}/${GRAILS_ZIP_FILE_NAME} -d /opt
    sudo rm -f /opt/${GRAILS_NAME}
    sudo ln -sf /opt/${GRAILS_DIR_NAME} /opt/${GRAILS_NAME}
}

LEININGEN_NAME=lein
LEININGEN_FILE_NAME=lein
LEININGEN_FILE_URL=https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/${LEININGEN_FILE_NAME}
leiningen_download_func() {
    smi-download ${LEININGEN_FILE_URL} ${HOME_PACKAGES_DIR}/${LEININGEN_FILE_NAME}
}
leiningen_install_func() {
    sudo mkdir -p /opt/leiningen/bin
    sudo mkdir -p /opt/leiningen/lib
    sudo mkdir -p /opt/leiningen/self-installs
    sudo cp ${HOME_PACKAGES_DIR}/${LEININGEN_FILE_NAME} /opt/leiningen/bin
    sudo chmod ugo+x /opt/leiningen/bin/lein
    sudo /opt/leiningen/bin/lein self-insstall
}

kubectl_download_func() {
    # yum config is already installed.
    return
}
kubectl_install_func() {
    sudo dnf config-manager --set-enabled kubernetes
    # dnf --enablerepo=kubernetes install 
    sudo dnf install -y kubectl
}

MINIKUBE_NAME=minikube
MINIKUBE_RPM_FILE_NAME=minikube-latest.x86_64.rpm
MINIKUBE_RPM_FILE_URL=https://storage.googleapis.com/minikube/releases/latest/{MINIKUBE_VERSION}/${MINIKUBE_RPM_FILE_NAME}
minikube_download_func() {
    smi-download ${MINIKUBE_RPM_FILE_URL} ${HOME_PACKAGES_DIR}/${MINIKUBE_RPM_FILE_NAME}
}
minikube_install_func() {
    sudo rpm -Uvh ${HOME_PACKAGES_DIR}/${MINIKUBE_RPM_FILE_NAME}
}

ARGOCLI_NAME=argo
ARGOCLI_VERSION=3.4.11
ARGOCLI_DIR_NAME=${ARGOCLI_NAME}-linux-amd64
ARGOCLI_GZ_FILE_NAME=${ARGOCLI_DIR_NAME}.gz
ARGOCLI_GZ_FILE_URL=https://github.com/argoproj/argo-workflows/releases/download/v${ARGOCLI_VERSION}/${ARGOCLI_GZ_FILE_NAME}
argocli_download_func() {
    smi-download ${ARGOCLI_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${ARGOCLI_GZ_FILE_NAME}
}
argocli_install_func() {
    CURRENT_DIR=$(pwd)
    cd /opt
    sudo gunzip ${HOME_PACKAGES_DIR}/${ARGOCLI_GZ_FILE_NAME}
    sudo rm -f /opt/${ARGOCLI_NAME}
    sudo ln -sf /opt/${ARGOCLI_DIR_NAME} /opt/${ARGOCLI_NAME}
    cd ${CURRENT_DIR}
}

docker_download_func() {
    return
}
docker_install_func() {
    sudo dnf remove -y --setopt=obsoletes=1 docker \
                      docker-client \
                      docker-client-latest \
                      docker-common \
                      docker-latest \
                      docker-latest-logrotate \
                      docker-logrotate \
                      docker-engine \
                      podman \
                      runc
    sudo dnf install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}
NGINX_VERSION=1.24.0
nginx_download_func() {
    return
}
nginx_install_func() {
    sudo dnf install -y yum-utils
    sudo dnf config-manager --set-enabled nginx-stable
    sudo dnf install -y nginx
}

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
    SYS_PACKAGE_FILE_NAME=${SYSTEM_PACKAGES_DIR}/${PACKAGE_NAME}.${PACKAGE_PREFIX}
    HOME_PACKAGE_FILE_NAME=${HOME_PACKAGES_DIR}/${PACKAGE_NAME}.${PACKAGE_PREFIX}
    if [ -f "${SYS_PACKAGE_FILE_NAME}" ]; then
        . ${SYS_PACKAGE_FILE_NAME}
    fi
    if [ -f "${HOME_PACKAGE_FILE_NAME}" ]; then
        . ${HOME_PACKAGE_FILE_NAME}
    fi
}
