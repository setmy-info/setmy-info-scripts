DISKLESS_DIR=/var/opt/setmy.info/diskless

do_diskless_isntall() {
    DISKLESS_NAME=${1}
    SERVER_IP=${2}
    pre_diskless_install
    make_diskless_directories ${DISKLESS_NAME}
    install_diskless ${DISKLESS_NAME}
    config_diskless ${DISKLESS_NAME} ${SERVER_IP}
    config_diskless_server ${DISKLESS_NAME}
    post_diskless_install
}

pre_diskless_install() {
    sudo dnf install -y dhcp-server tftp-server nfs-server nfs-utils
}

make_diskless_directories() {
    DISKLESS_NAME=${1}
    NAMED_DISKLESS_DIR=${DISKLESS_DIR}/${DISKLESS_NAME}
    DISKLESS_ROOT_DIR=${NAMED_DISKLESS_DIR}/root
    sudo mkdir -p ${NAMED_DISKLESS_DIR}
    sudo mkdir -p ${DISKLESS_ROOT_DIR}
    sudo mkdir -p ${DISKLESS_ROOT_DIR}/proc
    sudo mkdir -p ${NAMED_DISKLESS_DIR}/home
    sudo mkdir -p ${NAMED_DISKLESS_DIR}/var
}

install_diskless() {
    install_diskless_root ${DISKLESS_NAME}
    install_diskless_tftp_boot_kernel
}

install_diskless_root() {
    DISKLESS_NAME=${1}
    NAMED_DISKLESS_DIR=${DISKLESS_DIR}/${DISKLESS_NAME}
    DISKLESS_ROOT_DIR=${NAMED_DISKLESS_DIR}/root
    sudo dnf    --releasever=9.2 \
                --disablerepo=docker-ce-stable,epel,nginx,nginx-stable,nginx-mainline,pgAdmin4,pgdg-common,pgdg16,pgdg15,pgdg14,pgdg13,pgdg12,pgdg11 \
                --installroot=${DISKLESS_ROOT_DIR} \
                -y install \
                @core kernel nfs-utils dbus
}

install_diskless_tftp_boot_kernel() {
    ISO_LINUX_URL=https://download.rockylinux.org/pub/rocky/9.2/BaseOS/x86_64/kickstart/isolinux
    TFTP_BOOT_DIR=/var/lib/tftpboot
    if [ ! -f ${TFTP_BOOT_DIR}/pxelinux.0 ]; then
        sudo cp /usr/share/syslinux/pxelinux.0          ${TFTP_BOOT_DIR}/pxelinux.0
        sudo smi-download ${ISO_LINUX_URL}/boot.msg     ${TFTP_BOOT_DIR}/boot.msg
        sudo smi-download ${ISO_LINUX_URL}/grub.conf    ${TFTP_BOOT_DIR}/grub.conf
        sudo smi-download ${ISO_LINUX_URL}/initrd.img   ${TFTP_BOOT_DIR}/initrd.img
        sudo smi-download ${ISO_LINUX_URL}/isolinux.bin ${TFTP_BOOT_DIR}/isolinux.bin
        sudo smi-download ${ISO_LINUX_URL}/isolinux.cfg ${TFTP_BOOT_DIR}/isolinux.cfg
        sudo smi-download ${ISO_LINUX_URL}/ldlinux.c32  ${TFTP_BOOT_DIR}/ldlinux.c32
        sudo smi-download ${ISO_LINUX_URL}/libcom32.c32 ${TFTP_BOOT_DIR}/libcom32.c32
        sudo smi-download ${ISO_LINUX_URL}/libutil.c32  ${TFTP_BOOT_DIR}/libutil.c32
        sudo smi-download ${ISO_LINUX_URL}/memtest      ${TFTP_BOOT_DIR}/memtest
        sudo smi-download ${ISO_LINUX_URL}/splash.png   ${TFTP_BOOT_DIR}/splash.png
        sudo smi-download ${ISO_LINUX_URL}/vesamenu.c32 ${TFTP_BOOT_DIR}/vesamenu.c32
        sudo smi-download ${ISO_LINUX_URL}/vmlinuz      ${TFTP_BOOT_DIR}/vmlinuz
    fi
}

config_diskless() {
    DISKLESS_NAME=${1}
    NFS_ROOT_SERVER_IP=${2}
    NAMED_DISKLESS_DIR=${DISKLESS_DIR}/${DISKLESS_NAME}
    DISKLESS_ROOT_DIR=${NAMED_DISKLESS_DIR}/root

    DISKLESS_FSTAB_FILE=${DISKLESS_ROOT_DIR}/etc/fstab
    sudo echo "proc /proc proc defaults 0 0"                                            >> ${DISKLESS_FSTAB_FILE}
    sudo echo "${NFS_ROOT_SERVER_IP}:${NAMED_DISKLESS_DIR}/home /home nfs defaults 0 0" >> ${DISKLESS_FSTAB_FILE}
    sudo echo "${NFS_ROOT_SERVER_IP}:${NAMED_DISKLESS_DIR}/var  /var  nfs defaults 0 0" >> ${DISKLESS_FSTAB_FILE}
    # Disable SELinux inside diskless device
    sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' ${DISKLESS_FSTAB_FILE}/etc/selinux/config
}

config_diskless_server() {
    DISKLESS_NAME=${1}
    config_diskless_nfs_server ${DISKLESS_NAME}
    config_diskless_dhcp_server
    diskless_tftp_boot_options
}

config_diskless_nfs_server() {
    DISKLESS_NAME=${1}
    NAMED_DISKLESS_DIR=${DISKLESS_DIR}/${DISKLESS_NAME}
    DISKLESS_ROOT_DIR=${NAMED_DISKLESS_DIR}/root

    EXPORTS_FILE_NAME=/etc/exports
    # TODO : ro
    sudo echo "${DISKLESS_ROOT_DIR} *(rw,sync,no_root_squash)"       >> ${EXPORTS_FILE_NAME}
    sudo echo "${NAMED_DISKLESS_DIR}/home *(rw,sync,no_root_squash)" >> ${EXPORTS_FILE_NAME}
    sudo echo "${NAMED_DISKLESS_DIR}/var *(rw,sync,no_root_squash)"  >> ${EXPORTS_FILE_NAME}
}

config_diskless_dhcp_server() {
    DHCP_CONF_FILE_NAME=/etc/dhcp/dhcpd.conf
    sudo echo "default-lease-time 600;" > ${DHCP_CONF_FILE_NAME}
    sudo echo "max-lease-time 7200;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "option subnet-mask 255.0.0.0;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "option broadcast-address 10.255.255.255;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "option routers 10.0.0.1;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "option domain-name-servers 10.0.0.2, 10.0.0.2;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "option domain-search "has.ee.gintra";" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "next-server 10.0.0.2;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "# Interface where DHCP should work" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "#interface eth0;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "# Probably PXE boot works without these" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "#allow booting;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "#allow bootp;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "class "pxeclients" {" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "match if substring(option vendor-class-identifier, 0, 9) = "PXEClient";" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "next-server 10.0.0.2;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "filename "pxelinux.0";" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "}" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "subnet 10.0.0.0 netmask 255.0.0.0 {" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "range 10.0.0.100 10.0.0.254;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "}" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "host fedora {" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "hardware ethernet 66:FB:8B:4F:AC:3A;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "fixed-address 10.0.0.11;" >> ${DHCP_CONF_FILE_NAME}
    sudo echo "}" >> ${DHCP_CONF_FILE_NAME}
}

diskless_tftp_boot_options() {
    TFTP_BOOT_DIR=/var/lib/tftpboot
    TFTP_CFG_DIR=${TFTP_BOOT_DIR}/pxelinux.cfg
    DEFAULT_CFG_FILE=${TFTP_CFG_DIR}/default
    sudo mkdir -p ${TFTP_CFG_DIR}
    sudo echo "DEFAULT linux" >> ${DEFAULT_CFG_FILE}
    sudo echo "    LABEL linux" >> ${DEFAULT_CFG_FILE}
    # TODO : recheck and test
    sudo echo "    KERNEL /boot/vmlinuz-5.14.0-284.30.1.el9_2.x86_64" >> ${DEFAULT_CFG_FILE}
    sudo echo "    APPEND initrd=initramfs-5.14.0-284.30.1.el9_2.x86_64.img root=/dev/nfs nfsroot=nfs.has.ee.gintra:/var/opt/setmy.info/diskless/chroot ip=dhcp rw" >> ${DEFAULT_CFG_FILE}
}

post_diskless_install() {
    sudo systemctl enable dhcp-server
    sudo firewall-cmd --add-port=67/udp --permanent
    sudo firewall-cmd --reload

    sudo systemctl enable --now tftp
    sudo systemctl restart tftp
    sudo systemctl enable tftp

    sudo systemctl enable --now rpcbind nfs-server
    sudo systemctl enable nfs-server
    sudo firewall-cmd --add-service=nfs --permanent
}

start_diskless_servers() {
    sudo systemctl restart dhcp-server
    sudo systemctl restart tftp
    sudo systemctl restart nfs-server
}

diskless_useradd() {
    DISKLESS_NAME=${1}
    USER_NAME=${2}
    NAMED_DISKLESS_DIR=${DISKLESS_DIR}/${DISKLESS_NAME}
    DISKLESS_ROOT_DIR=${NAMED_DISKLESS_DIR}/root

    sudo chroot ${DISKLESS_ROOT_DIR} sudo useradd ${USER_NAME} && exit
}

diskless_passwd() {
    DISKLESS_NAME=${1}
    USER_NAME=${2}
    NAMED_DISKLESS_DIR=${DISKLESS_DIR}/${DISKLESS_NAME}
    DISKLESS_ROOT_DIR=${NAMED_DISKLESS_DIR}/root

    sudo setenforce 0
    sudo chroot ${DISKLESS_ROOT_DIR} sudo passwd ${USER_NAME} && exit
    sudo setenforce 1
}
