FROM debian:latest AS deb_build_image

RUN apt-get -y update && apt-get -y upgrade && mkdir -p /var/opt/setmy.info/build && \
    apt-get -y install cpp gcc g++ make dos2unix gzip bzip2 xz-utils zip

WORKDIR /opt
ADD https://github.com/Kitware/CMake/releases/download/v3.30.2/cmake-3.30.2-linux-x86_64.tar.gz /opt
RUN tar xvzf cmake-3.30.2-linux-x86_64.tar.gz && ln -s /opt/cmake-3.30.2-linux-x86_64 /opt/cmake && ls -la

WORKDIR /var/opt/setmy.info/build

COPY ./src/ ./src/
COPY CMakeLists.txt ./
COPY configure ./
COPY changelog ./
RUN dos2unix **/* && dos2unix ./configure && dos2unix ./src/main/sh/build/packages-build.sh &&  chmod ugoa+x ./src/main/sh/build/packages-build.sh

RUN ./src/main/sh/build/packages-build.sh

RUN ls -la
RUN apt install ./setmy-info-scripts-0.96.0.noarch.deb
RUN ls -la /opt/setmy.info

FROM setmyinfo/setmy-info-rocky:latest AS rpm_build_image

RUN dnf install -y epel-release && \
    dnf --enablerepo=epel group && \
    dnf config-manager --set-enabled crb && \
    dnf config-manager --set-enabled plus && \
    dnf config-manager --set-enabled rt && \
    dnf update -y && \
    mkdir -p /var/opt/setmy.info/build && \
    dnf install -y cpp gcc g++ boost-test make dos2unix yum-utils rpmdevtools rpm-build rpm rpmlint

WORKDIR /opt
ADD https://github.com/Kitware/CMake/releases/download/v3.30.2/cmake-3.30.2-linux-x86_64.tar.gz /opt
RUN tar xvzf cmake-3.30.2-linux-x86_64.tar.gz && ln -s /opt/cmake-3.30.2-linux-x86_64 /opt/cmake && ls -la

WORKDIR /var/opt/setmy.info/build

COPY ./src/ ./src/
COPY CMakeLists.txt ./
COPY configure ./
COPY changelog ./
RUN dos2unix **/* && dos2unix ./configure && dos2unix ./src/main/sh/build/packages-build.sh &&  chmod ugoa+x ./src/main/sh/build/packages-build.sh
COPY --from=deb_build_image /var/opt/setmy.info/build/setmy-info-scripts-0.96.0.noarch.deb /var/opt/setmy.info/build/setmy-info-scripts-0.96.0.noarch.deb

RUN ./src/main/sh/build/packages-build.sh
RUN ls -la
#RUN rpm -i ./setmy-info-scripts-0.96.0.noarch.rpm
#RUN ls -la /opt/setmy.info
