HOME_PACKAGES_DIR=$(smi-home-packages-location)

all_download_func() {
    downloadPackages sbcl jdk zulu_jdk jdk17 jdk21 tomcat zeebe infinispan hsqldb hsqldb nodejs maven gradle cmake julia go dvc jenkins groovy mn grails leiningen
}

SBCL_VERSION=2.3.8
SBCL_DIR_NAME=sbcl-${SBCL_VERSION}-x86-64-linux-binary
SBCL_TAR_FILE_NAME=${SBCL_DIR_NAME}.tar
SBCL_TAR_BZ2_FILE_NAME=${SBCL_TAR_FILE_NAME}.bz2
SBCL_TAR_BZ2_FILE_URL=http://prdownloads.sourceforge.net/sbcl/${SBCL_TAR_BZ2_FILE_NAME}
sbcl_download_func() {
    smi-download ${SBCL_TAR_BZ2_FILE_URL} ${HOME_PACKAGES_DIR}/${SBCL_TAR_BZ2_FILE_NAME}
}
sbcl_install_func() {
    return
}

JDK_VERSION=20.0.2
JDK_HASH=6e380f22cbe7469fa75fb448bd903d8e
JDK_URI_NR_PART=9
JDK_DIR_NAME=jdk-${JDK_VERSION}
JDK_NAME_PREFIX=openjdk-${JDK_VERSION}
JDK_TAR_FILE_NAME=${JDK_NAME_PREFIX}_linux-x64_bin.tar
JDK_TAR_GZ_FILE_NAME=${JDK_TAR_FILE_NAME}.gz
JDK_TAR_GZ_FILE_URL=https://download.java.net/java/GA/jdk${JDK_VERSION}/${JDK_HASH}/${JDK_URI_NR_PART}/GPL/${JDK_TAR_GZ_FILE_NAME}
jdk_download_func() {
    smi-download ${JDK_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${JDK_TAR_GZ_FILE_NAME}
}
jdk_install_func() {
    tar -xvzf --overwrite ${HOME_PACKAGES_DIR}/${JDK_TAR_GZ_FILE_NAME} -C /opt
    ln -sf /opt/jdk /opt/${JDK_DIR_NAME}
}

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
    unzip ${HOME_PACKAGES_DIR}/${ZULU_JDK17_ZIP_FILE_NAME} -d /opt
    ln -sf /opt/zulu-jdk17 /opt/${ZULU_JDK17_DIR_NAME}
}

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
      return
}

JDK21_VERSION=21.0.0
JDK21_HASH_PART=dfd4a8d0985749f896bed50d7138ee7f
JDK21_NUMERIC_PART=8
JDK21_DIR_NAME=jdk-${JDK21_VERSION}
JDK21_NAME_PREFIX=openjdk-${JDK21_VERSION}
JDK21_TAR_FILE_NAME=${JDK21_NAME_PREFIX}_linux-x64_bin.tar
JDK21_TAR_GZ_FILE_NAME=${JDK21_TAR_FILE_NAME}.gz
JDK21_TAR_GZ_FILE_URL=https://download.java.net/java/GA/${JDK21_VERSION}/${JDK21_HASH_PART}/${JDK21_NUMERIC_PART}/GPL/${JDK21_TAR_GZ_FILE_NAME}
jdk21_download_func() {
    smi-download ${JDK21_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${JDK21_TAR_GZ_FILE_NAME}
}
jdk21_install_func() {
      return
}

TOMCAT_MAJOR_VERSION=10
TOMCAT_VERSION=${TOMCAT_MAJOR_VERSION}.1.13
TOMCAT_DIR_NAME=apache-tomcat-${TOMCAT_VERSION}
TOMCAT_TAR_FILE_NAME=${TOMCAT_DIR_NAME}.tar
TOMCAT_TAR_GZ_FILE_NAME=${TOMCAT_TAR_FILE_NAME}.gz
TOMCAT_TAR_GZ_FILE_URL=https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/${TOMCAT_TAR_GZ_FILE_NAME}
tomcat_download_func() {
    smi-download ${TOMCAT_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${TOMCAT_TAR_GZ_FILE_NAME}
}
tomcat_install_func() {
    return
}

ZEEBE_VERSION=8.0.21
ZEEBE_DIR_NAME=camunda-zeebe-${ZEEBE_VERSION}
ZEEBE_TAR_FILE_NAME=${ZEEBE_DIR_NAME}.tar
ZEEBE_TAR_GZ_FILE_NAME=${ZEEBE_TAR_FILE_NAME}.gz
ZEEBE_TAR_GZ_FILE_URL=https://github.com/camunda/zeebe/releases/download/${ZEEBE_VERSION}/${ZEEBE_TAR_GZ_FILE_NAME}
zeebe_download_func() {
    smi-download ${ZEEBE_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${ZEEBE_TAR_GZ_FILE_NAME}
}
zeebe_install_func() {
      return
}

INFINISPAN_VERSION=14.0.13
INFINISPAN_DIR_NAME=infinispan-server-${INFINISPAN_VERSION}.Final
INFINISPAN_ZIP_FILE_NAME=${INFINISPAN_DIR_NAME}.zip
INFINISPAN_ZIP_FILE_URL=https://downloads.jboss.org/infinispan/${INFINISPAN_VERSION}.Final/${INFINISPAN_ZIP_FILE_NAME}
infinispan_download_func() {
    smi-download ${INFINISPAN_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${INFINISPAN_ZIP_FILE_NAME}
}
infinispan_install_func() {
      return
}

HSQLDB_VERSION=2.7.2
HSQLDB_DIR_NAME=hsqldb-${HSQLDB_VERSION}
HSQLDB_ZIP_FILE_NAME=${HSQLDB_DIR_NAME}.zip
HSQLDB_ZIP_FILE_URL=https://altushost-swe.dl.sourceforge.net/project/hsqldb/hsqldb/hsqldb_2_7/${HSQLDB_ZIP_FILE_NAME}
hsqldb_download_func() {
    smi-download ${HSQLDB_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${HSQLDB_ZIP_FILE_NAME}
}
hsqldb_install_func() {
      return
}

NODE_VERSION=18.17.1
NODE_DIR_NAME=node-v${NODE_VERSION}-linux-x64
NODE_TAR_FILE_NAME=${NODE_DIR_NAME}.tar
NODE_TAR_XZ_FILE_NAME=${NODE_TAR_FILE_NAME}.xz
NODE_TAR_XZ_FILE_URL=https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TAR_XZ_FILE_NAME}
nodejs_download_func() {
    smi-download ${NODE_TAR_XZ_FILE_URL} ${HOME_PACKAGES_DIR}/${NODE_TAR_XZ_FILE_NAME}
}
nodejs_install_func() {
      return
}

MAVEN_VERSION=3.9.4
MAVEN_DIR_NAME=apache-maven-${MAVEN_VERSION}
MAVEN_TAR_FILE_NAME=${MAVEN_DIR_NAME}-bin.tar
MAVEN_TAR_GZ_FILE_NAME=${MAVEN_TAR_FILE_NAME}.gz
MAVEN_TAR_GZ_FILE_URL=https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
maven_download_func() {
    smi-download ${MAVEN_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${MAVEN_TAR_GZ_FILE_NAME}
}
maven_install_func() {
      return
}

GRADLE_VERSION=8.3
GRADLE_DIR_NAME=gradle-${GRADLE_VERSION}
GRADLE_ZIP_FILE_NAME=${GRADLE_DIR_NAME}-bin.zip
GRADLE_ZIP_FILE_URL=https://services.gradle.org/distributions/${GRADLE_ZIP_FILE_NAME}
gradle_download_func() {
    smi-download ${GRADLE_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${GRADLE_ZIP_FILE_NAME}
}
gradle_install_func() {
      return
}

CMAKE_VERSION=3.27.4
CMAKE_DIR_NAME=cmake-${CMAKE_VERSION}-linux-x86_64
CMAKE_TAR_FILE_NAME=${CMAKE_DIR_NAME}.tar
CMAKE_TAR_GZ_FILE_NAME=${CMAKE_TAR_FILE_NAME}.gz
CMAKE_TAR_GZ_FILE_URL=https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_TAR_GZ_FILE_NAME}
cmake_download_func() {
    smi-download ${CMAKE_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${CMAKE_TAR_GZ_FILE_NAME}
}
cmake_install_func() {
      return
}

JULIA_BASE_VERSION=1.9
JULIA_VERSION=${JULIA_BASE_VERSION}.2
JULIA_DIR_NAME=julia-${JULIA_VERSION}
JULIA_TAR_FILE_NAME=${JULIA_DIR_NAME}-linux-x86_64.tar
JULIA_TAR_GZ_FILE_NAME=${JULIA_TAR_FILE_NAME}.gz
JULIA_TAR_GZ_FILE_URL=https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_BASE_VERSION}/${JULIA_TAR_GZ_FILE_NAME}
julia_download_func() {
    smi-download ${JULIA_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${JULIA_TAR_GZ_FILE_NAME}
}
julia_install_func() {
      return
}

GO_VERSION=1.21.1
GO_DIR_NAME=go
GO_TAR_FILE_NAME=${GO_DIR_NAME}${GO_VERSION}.linux-amd64.tar
GO_TAR_GZ_FILE_NAME=${GO_TAR_FILE_NAME}.gz
GO_TAR_GZ_FILE_URL=https://go.dev/dl/${GO_TAR_GZ_FILE_NAME}
go_download_func() {
    smi-download ${GO_TAR_GZ_FILE_URL} ${HOME_PACKAGES_DIR}/${GO_TAR_GZ_FILE_NAME}
}
go_install_func() {
      return
}

DVC_VERSION=3.19.0
DVC_DIR_NAME=dvc-${DVC_VERSION}-1.x86_64
DVC_RPM_FILE_NAME=${DVC_DIR_NAME}.rpm
DVC_RPM_FILE_URL=https://s3-us-east-2.amazonaws.com/dvc-s3-repo/rpm/${DVC_RPM_FILE_NAME}
dvc_download_func() {
    smi-download ${DVC_RPM_FILE_URL} ${HOME_PACKAGES_DIR}/${DVC_RPM_FILE_NAME}
}
dvc_install_func() {
      return
}

JENKINS_VERSION=2.414.1
JENKINS_DIR_NAME=jenkins
JENKINS_WAR_FILE_NAME=${JENKINS_DIR_NAME}.war
JENKINS_WAR_FILE_URL=https://ftp.halifax.rwth-aachen.de/jenkins/war-stable/${JENKINS_VERSION}/${JENKINS_WAR_FILE_NAME}
jenkins_download_func() {
    smi-download ${JENKINS_WAR_FILE_URL} ${HOME_PACKAGES_DIR}/${JENKINS_WAR_FILE_NAME}
}
jenkins_install_func() {
      return
}

JENKINS_HOME_VERSION=1.0.1
JENKINS_HOME_DIR_NAME=jenkins
JENKINS_HOME_TAR_FILE_NAME=${JENKINS_HOME_DIR_NAME}-${JENKINS_HOME_VERSION}.tar
JENKINS_HOME_TAR_GZ_FILE_NAME=${JENKINS_HOME_TAR_FILE_NAME}.gz
jenkins_home_download_func() {
    #smi-download ${JENKINS_HOME_TAR_GZ_FILE_NAME} ${HOME_PACKAGES_DIR}/${JENKINS_HOME_TAR_FILE_NAME}
    return
}
jenkins_install_func() {
      return
}

GROOVY_VERSION=4.0.14
GROOVY_DIR_NAME=apache-groovy-sdk-${GROOVY_VERSION}
GROOVY_ZIP_FILE_NAME=${GROOVY_DIR_NAME}.zip
GROOVY_ZIP_FILE_URL="https://groovy.jfrog.io/ui/api/v1/download?repoKey=dist-release-local&path=groovy-zips%252F${GROOVY_ZIP_FILE_NAME}&isNativeBrowsing=true"
groovy_download_func() {
    smi-download ${GROOVY_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${GROOVY_ZIP_FILE_NAME}
}
groovy_install_func() {
      return
}

MN_VERSION=4.1.0
MN_DIR_NAME=micronaut-cli-${MN_VERSION}
MN_ZIP_FILE_NAME=${MN_DIR_NAME}.zip
MN_ZIP_FILE_URL=https://github.com/micronaut-projects/micronaut-starter/releases/download/v${MN_VERSION}/${MN_ZIP_FILE_NAME}
mn_download_func() {
    smi-download ${MN_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${MN_ZIP_FILE_NAME}
}
mn_install_func() {
      return
}

GRAILS_VERSION=6.0.0
GRAILS_DIR_NAME=grails-${GRAILS_VERSION}
GRAILS_ZIP_FILE_NAME=${GRAILS_DIR_NAME}.zip
GRAILS_ZIP_FILE_URL=https://github.com/grails/grails-core/releases/download/v${GRAILS_VERSION}/${GRAILS_ZIP_FILE_NAME}
grails_download_func() {
    smi-download ${GRAILS_ZIP_FILE_URL} ${HOME_PACKAGES_DIR}/${GRAILS_ZIP_FILE_NAME}
}
grails_install_func() {
      return
}

LEININGEN_FILE_NAME=lein
LEININGEN_FILE_URL=https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/${LEININGEN_FILE_NAME}
leiningen_download_func() {
    smi-download ${LEININGEN_FILE_URL} ${HOME_PACKAGES_DIR}/${LEININGEN_FILE_NAME}
}
leiningen_install_func() {
      return
}

kubectl_xx() {
    # This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
#    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
#    [kubernetes]
#    name=Kubernetes
#    baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
#    enabled=1
#    gpgcheck=1
#    gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
#    EOF
#    yum install -y kubectl

    # Minikube
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
    sudo rpm -Uvh minikube-latest.x86_64.rpm
}

createHomePackagesFolder() {
    mkdir -p ${HOME_PACKAGES_DIR}
}

downloadPackages() {
    INSTALLABLE_PACKAGES=${*}
    for INSTALLABLE_PACKAGE in ${INSTALLABLE_PACKAGES}; do
        downloadPackage ${INSTALLABLE_PACKAGE}
    done
    return
}

downloadPackage() {
    PACKAGE_NAME=${1}
    echo "Downloading package: ${PACKAGE_NAME}"
    ${PACKAGE_NAME}_download_func
    return
}

installPackages() {
    INSTALLABLE_PACKAGES=${*}
    for INSTALLABLE_PACKAGE in ${INSTALLABLE_PACKAGES}; do
        installPackage ${INSTALLABLE_PACKAGE}
    done
    return
}

installPackage() {
    PACKAGE_NAME=${1}
    ${PACKAGE_NAME}_install_func
    return
}
