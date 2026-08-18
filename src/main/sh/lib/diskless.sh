# Copyright (C) 2023 - etc Imre Tabur <imre.tabur@mail.ee>
#
# Diskless installation library.
#
# An installation is a directory tree below DISKLESS_DIR, prepared as a chroot
# installation and exported over NFS to the client that boots it over PXE:
#
#   DISKLESS_DIR/NAME/diskless.conf   settings of the installation
#   DISKLESS_DIR/NAME/root            the chroot, NFS root of the client
#   DISKLESS_DIR/NAME/home            exported as /home of the client
#   DISKLESS_DIR/NAME/var             exported as /var of the client
#
# The boot files of the client are below DISKLESS_TFTP_DIR/NAME: the kernel of
# the chroot and an initramfs generated in the chroot with the nfs module, so
# the client mounts its root over NFS. The installer initramfs of the
# distribution is not usable for that, it starts the installer.
#
# Every setting has a default and can be overridden from the environment.

: "${DISKLESS_DIR:=/var/opt/setmy.info/diskless}"
: "${DISKLESS_TFTP_DIR:=/var/lib/tftpboot}"

# Installation of the chroot
: "${DISKLESS_RELEASEVER:=10}"
: "${DISKLESS_REPOS:=baseos,appstream,extras}"
: "${DISKLESS_GROUPS:=@core}"
: "${DISKLESS_PACKAGES:=kernel dracut-network nfs-utils dbus openssh-server}"

# NFS
: "${DISKLESS_NFS_VERSION:=4.2}"
: "${DISKLESS_NFS_CLIENTS:=*}"
: "${DISKLESS_EXPORT_OPTIONS:=rw,sync,no_root_squash,no_subtree_check}"

# DHCP
: "${DISKLESS_DHCP_CONF_FILE:=/etc/dhcp/dhcpd.conf}"
: "${DISKLESS_DHCP_SUBNET:=10.0.0.0}"
: "${DISKLESS_DHCP_NETMASK:=255.0.0.0}"
: "${DISKLESS_DHCP_BROADCAST:=10.255.255.255}"
: "${DISKLESS_DHCP_RANGE_FROM:=10.0.0.100}"
: "${DISKLESS_DHCP_RANGE_TO:=10.0.0.254}"
: "${DISKLESS_DHCP_ROUTER:=10.0.0.1}"
: "${DISKLESS_DHCP_DNS:=10.0.0.2}"
: "${DISKLESS_DHCP_DOMAIN:=has.ee.gintra}"
: "${DISKLESS_DHCP_LEASE_TIME:=600}"
: "${DISKLESS_DHCP_MAX_LEASE_TIME:=7200}"

# Boot
: "${DISKLESS_SYSLINUX_DIR:=/usr/share/syslinux}"
: "${DISKLESS_EFI_DIR:=/boot/efi/EFI/rocky}"
: "${DISKLESS_EXPORTS_FILE:=/etc/exports}"
: "${DISKLESS_BOOT_TIMEOUT:=50}"
: "${DISKLESS_KERNEL_OPTIONS:=selinux=0}"

DISKLESS_BLOCK_BEGIN="# BEGIN setmy.info diskless"
DISKLESS_BLOCK_END="# END setmy.info diskless"

##############################################################################
# Helpers
##############################################################################

diskless_error() {
    echo "ERROR: ${*}" >&2
    return 1
}

# Writes standard input to a file as root. Needed because a redirection is
# done by the calling shell and not by sudo.
diskless_write() {
    sudo tee "${1}" > /dev/null
}

# Replaces the block of this installation in a configuration file with the
# standard input, keeping everything else of the file. Makes every
# configuration function repeatable without duplicating its lines.
diskless_write_block() {
    DISKLESS_BLOCK_FILE=${1}
    DISKLESS_BLOCK_NAME=${2}
    DISKLESS_BLOCK_TMP_FILE=$(mktemp)
    if [ -f "${DISKLESS_BLOCK_FILE}" ]; then
        sudo sed "/^${DISKLESS_BLOCK_BEGIN} ${DISKLESS_BLOCK_NAME}\$/,/^${DISKLESS_BLOCK_END} ${DISKLESS_BLOCK_NAME}\$/d" \
            "${DISKLESS_BLOCK_FILE}" > "${DISKLESS_BLOCK_TMP_FILE}"
    fi
    {
        echo "${DISKLESS_BLOCK_BEGIN} ${DISKLESS_BLOCK_NAME}"
        cat
        echo "${DISKLESS_BLOCK_END} ${DISKLESS_BLOCK_NAME}"
    } >> "${DISKLESS_BLOCK_TMP_FILE}"
    sudo cp "${DISKLESS_BLOCK_TMP_FILE}" "${DISKLESS_BLOCK_FILE}"
    rm -f "${DISKLESS_BLOCK_TMP_FILE}"
}

# Removes the block of this installation from a configuration file.
diskless_remove_block() {
    DISKLESS_BLOCK_FILE=${1}
    DISKLESS_BLOCK_NAME=${2}
    if [ ! -f "${DISKLESS_BLOCK_FILE}" ]; then
        return 0
    fi
    DISKLESS_BLOCK_TMP_FILE=$(mktemp)
    sudo sed "/^${DISKLESS_BLOCK_BEGIN} ${DISKLESS_BLOCK_NAME}\$/,/^${DISKLESS_BLOCK_END} ${DISKLESS_BLOCK_NAME}\$/d" \
        "${DISKLESS_BLOCK_FILE}" > "${DISKLESS_BLOCK_TMP_FILE}"
    sudo cp "${DISKLESS_BLOCK_TMP_FILE}" "${DISKLESS_BLOCK_FILE}"
    rm -f "${DISKLESS_BLOCK_TMP_FILE}"
}

# Directories and files of one installation.
diskless_paths() {
    DISKLESS_NAME=${1}
    if [ -z "${DISKLESS_NAME}" ]; then
        diskless_error "diskless name is required"
        return 1
    fi
    NAMED_DISKLESS_DIR=${DISKLESS_DIR}/${DISKLESS_NAME}
    DISKLESS_ROOT_DIR=${NAMED_DISKLESS_DIR}/root
    DISKLESS_HOME_DIR=${NAMED_DISKLESS_DIR}/home
    DISKLESS_VAR_DIR=${NAMED_DISKLESS_DIR}/var
    DISKLESS_CONF_FILE=${NAMED_DISKLESS_DIR}/diskless.conf
    DISKLESS_TFTP_NAME_DIR=${DISKLESS_TFTP_DIR}/${DISKLESS_NAME}
}

diskless_config_save() {
    {
        echo "# Written by smi-make-diskless(1). Read by the diskless commands."
        echo "DISKLESS_NAME=${DISKLESS_NAME}"
        echo "DISKLESS_SERVER_IP=${DISKLESS_SERVER_IP}"
        echo "DISKLESS_RELEASEVER=${DISKLESS_RELEASEVER}"
        echo "DISKLESS_NFS_VERSION=${DISKLESS_NFS_VERSION}"
        echo "DISKLESS_KERNEL_VERSION=${DISKLESS_KERNEL_VERSION}"
    } | diskless_write "${DISKLESS_CONF_FILE}"
}

# Loads the settings of an existing installation, so the management commands
# need the name only.
diskless_config_load() {
    diskless_paths "${1}" || return 1
    if [ ! -f "${DISKLESS_CONF_FILE}" ]; then
        diskless_error "${DISKLESS_NAME}: no such diskless installation in ${DISKLESS_DIR}"
        return 1
    fi
    . "${DISKLESS_CONF_FILE}"
    diskless_paths "${DISKLESS_NAME}"
}

# Kernel version of the chroot, the one the initramfs is generated for.
diskless_kernel_version() {
    sudo ls -1 "${DISKLESS_ROOT_DIR}/lib/modules" 2>/dev/null | sort -V | tail -1
}

##############################################################################
# chroot
##############################################################################

# The chroot needs the kernel file systems for dnf, dracut, passwd and useradd.
diskless_chroot_mount() {
    sudo mkdir -p "${DISKLESS_ROOT_DIR}/proc" \
                  "${DISKLESS_ROOT_DIR}/sys" \
                  "${DISKLESS_ROOT_DIR}/dev" \
                  "${DISKLESS_ROOT_DIR}/dev/pts" \
                  "${DISKLESS_ROOT_DIR}/run"
    mountpoint -q "${DISKLESS_ROOT_DIR}/proc"    || sudo mount -t proc proc   "${DISKLESS_ROOT_DIR}/proc"    || return 1
    mountpoint -q "${DISKLESS_ROOT_DIR}/sys"     || sudo mount -t sysfs sys   "${DISKLESS_ROOT_DIR}/sys"     || return 1
    mountpoint -q "${DISKLESS_ROOT_DIR}/dev"     || sudo mount --bind /dev    "${DISKLESS_ROOT_DIR}/dev"     || return 1
    mountpoint -q "${DISKLESS_ROOT_DIR}/dev/pts" || sudo mount --bind /dev/pts "${DISKLESS_ROOT_DIR}/dev/pts" || return 1
    mountpoint -q "${DISKLESS_ROOT_DIR}/run"     || sudo mount -t tmpfs tmpfs "${DISKLESS_ROOT_DIR}/run"     || return 1
    # Name resolution for dnf in the chroot. The file of the host can be a
    # symbolic link to a file that is not there, so it is dereferenced and a
    # failure does not stop the caller.
    if [ -r /etc/resolv.conf ]; then
        sudo cp -f -L /etc/resolv.conf "${DISKLESS_ROOT_DIR}/etc/resolv.conf"
    fi
    return 0
}

# Unmounts in the reverse order. A lazy unmount is the fallback, so a busy
# mount can never keep the installation directory locked.
diskless_chroot_umount() {
    for DISKLESS_MOUNT in run dev/pts dev sys proc; do
        if mountpoint -q "${DISKLESS_ROOT_DIR}/${DISKLESS_MOUNT}"; then
            sudo umount "${DISKLESS_ROOT_DIR}/${DISKLESS_MOUNT}" 2>/dev/null || \
            sudo umount -l "${DISKLESS_ROOT_DIR}/${DISKLESS_MOUNT}"
        fi
    done
}

# Runs a command in the chroot, an interactive shell without a command.
diskless_chroot_run() {
    if [ ! -d "${DISKLESS_ROOT_DIR}" ]; then
        diskless_error "${DISKLESS_ROOT_DIR}: no such directory"
        return 1
    fi
    diskless_chroot_mount || return 1
    if [ ${#} -eq 0 ]; then
        sudo chroot "${DISKLESS_ROOT_DIR}" /bin/sh -l
    else
        sudo chroot "${DISKLESS_ROOT_DIR}" "${@}"
    fi
    DISKLESS_CHROOT_STATUS=${?}
    diskless_chroot_umount
    return ${DISKLESS_CHROOT_STATUS}
}

##############################################################################
# Installation
##############################################################################

do_diskless_install() {
    DISKLESS_SERVER_IP=${2}
    diskless_paths "${1}" || return 1
    if [ -z "${DISKLESS_SERVER_IP}" ]; then
        diskless_error "server IP address is required"
        return 1
    fi
    pre_diskless_install && \
    make_diskless_directories "${DISKLESS_NAME}" && \
    install_diskless "${DISKLESS_NAME}" && \
    config_diskless "${DISKLESS_NAME}" "${DISKLESS_SERVER_IP}" && \
    diskless_config_save && \
    config_diskless_server "${DISKLESS_NAME}" && \
    post_diskless_install
}

pre_diskless_install() {
    sudo dnf install -y dhcp-server tftp-server nfs-utils dracut-network rsync
}

make_diskless_directories() {
    diskless_paths "${1}" || return 1
    sudo mkdir -p "${NAMED_DISKLESS_DIR}" \
                  "${DISKLESS_ROOT_DIR}" \
                  "${DISKLESS_HOME_DIR}" \
                  "${DISKLESS_VAR_DIR}" \
                  "${DISKLESS_TFTP_NAME_DIR}"
}

install_diskless() {
    diskless_paths "${1}" || return 1
    install_diskless_root "${DISKLESS_NAME}" && \
    install_diskless_initramfs "${DISKLESS_NAME}" && \
    install_diskless_boot_files "${DISKLESS_NAME}"
}

# Installs the distribution into the chroot. Only the distribution repositories
# are used, so no third party repository of the host leaks into the client.
install_diskless_root() {
    diskless_paths "${1}" || return 1
    sudo dnf --releasever="${DISKLESS_RELEASEVER}" \
             --installroot="${DISKLESS_ROOT_DIR}" \
             --disablerepo="*" \
             --enablerepo="${DISKLESS_REPOS}" \
             -y install ${DISKLESS_GROUPS} ${DISKLESS_PACKAGES}
}

# Generates the initramfs of the client in the chroot. The nfs and network
# modules are the ones that let the client mount its root over NFS, and
# no-hostonly keeps the drivers of the host out of it.
install_diskless_initramfs() {
    diskless_paths "${1}" || return 1
    DISKLESS_KERNEL_VERSION=$(diskless_kernel_version)
    if [ -z "${DISKLESS_KERNEL_VERSION}" ]; then
        diskless_error "${DISKLESS_ROOT_DIR}: no kernel installed"
        return 1
    fi
    echo "Generating initramfs for kernel ${DISKLESS_KERNEL_VERSION}"
    diskless_chroot_run dracut --force \
                               --no-hostonly \
                               --add "nfs network" \
                               "/boot/initramfs-${DISKLESS_KERNEL_VERSION}-diskless.img" \
                               "${DISKLESS_KERNEL_VERSION}"
}

# Copies the kernel and the initramfs of the chroot to the TFTP directory of
# this installation.
install_diskless_boot_files() {
    diskless_paths "${1}" || return 1
    : "${DISKLESS_KERNEL_VERSION:=$(diskless_kernel_version)}"
    sudo mkdir -p "${DISKLESS_TFTP_NAME_DIR}"
    sudo cp -f "${DISKLESS_ROOT_DIR}/boot/vmlinuz-${DISKLESS_KERNEL_VERSION}" \
               "${DISKLESS_TFTP_NAME_DIR}/vmlinuz" || return 1
    sudo cp -f "${DISKLESS_ROOT_DIR}/boot/initramfs-${DISKLESS_KERNEL_VERSION}-diskless.img" \
               "${DISKLESS_TFTP_NAME_DIR}/initramfs.img" || return 1
}

##############################################################################
# Configuration of the client
##############################################################################

config_diskless() {
    diskless_paths "${1}" || return 1
    DISKLESS_SERVER_IP=${2}
    config_diskless_fstab "${DISKLESS_NAME}" "${DISKLESS_SERVER_IP}" && \
    config_diskless_selinux "${DISKLESS_NAME}" && \
    config_diskless_hostname "${DISKLESS_NAME}" && \
    config_diskless_exported_directories "${DISKLESS_NAME}"
}

# The root is mounted by the initramfs, so only the directories that are
# exported separately are in the fstab of the client.
config_diskless_fstab() {
    diskless_paths "${1}" || return 1
    DISKLESS_SERVER_IP=${2}
    DISKLESS_FSTAB_FILE=${DISKLESS_ROOT_DIR}/etc/fstab
    diskless_write_block "${DISKLESS_FSTAB_FILE}" "${DISKLESS_NAME}" <<EOF
proc /proc proc defaults 0 0
${DISKLESS_SERVER_IP}:${DISKLESS_HOME_DIR} /home nfs defaults,vers=${DISKLESS_NFS_VERSION} 0 0
${DISKLESS_SERVER_IP}:${DISKLESS_VAR_DIR}  /var  nfs defaults,vers=${DISKLESS_NFS_VERSION} 0 0
EOF
}

# SELinux is disabled inside the diskless client, its labels cannot be kept on
# the NFS root.
config_diskless_selinux() {
    diskless_paths "${1}" || return 1
    DISKLESS_SELINUX_FILE=${DISKLESS_ROOT_DIR}/etc/selinux/config
    if [ -f "${DISKLESS_SELINUX_FILE}" ]; then
        sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' "${DISKLESS_SELINUX_FILE}"
    fi
}

# The machine id is emptied, so every client generates its own on boot.
config_diskless_hostname() {
    diskless_paths "${1}" || return 1
    echo "${DISKLESS_NAME}" | diskless_write "${DISKLESS_ROOT_DIR}/etc/hostname"
    printf "" | diskless_write "${DISKLESS_ROOT_DIR}/etc/machine-id"
}

# The client mounts home and var over the directories of the chroot, so the
# exported directories are seeded with the content the installation created.
config_diskless_exported_directories() {
    diskless_paths "${1}" || return 1
    sudo rsync -a "${DISKLESS_ROOT_DIR}/var/" "${DISKLESS_VAR_DIR}/" && \
    sudo rsync -a "${DISKLESS_ROOT_DIR}/home/" "${DISKLESS_HOME_DIR}/"
}

##############################################################################
# Configuration of the server
##############################################################################

config_diskless_server() {
    diskless_paths "${1}" || return 1
    config_diskless_nfs_server "${DISKLESS_NAME}" && \
    config_diskless_dhcp_server && \
    diskless_tftp_boot_options
}

config_diskless_nfs_server() {
    diskless_paths "${1}" || return 1
    diskless_write_block "${DISKLESS_EXPORTS_FILE}" "${DISKLESS_NAME}" <<EOF
${DISKLESS_ROOT_DIR} ${DISKLESS_NFS_CLIENTS}(${DISKLESS_EXPORT_OPTIONS})
${DISKLESS_HOME_DIR} ${DISKLESS_NFS_CLIENTS}(${DISKLESS_EXPORT_OPTIONS})
${DISKLESS_VAR_DIR} ${DISKLESS_NFS_CLIENTS}(${DISKLESS_EXPORT_OPTIONS})
EOF
    sudo exportfs -r
}

# The whole file is written, it is the configuration of the diskless server.
# The architecture option selects the boot file, so UEFI and BIOS clients boot
# from the same server.
config_diskless_dhcp_server() {
    if [ -z "${DISKLESS_SERVER_IP}" ]; then
        diskless_error "DISKLESS_SERVER_IP is not set"
        return 1
    fi
    diskless_write "${DISKLESS_DHCP_CONF_FILE}" <<EOF
# Written by smi-make-diskless(1).

default-lease-time ${DISKLESS_DHCP_LEASE_TIME};
max-lease-time ${DISKLESS_DHCP_MAX_LEASE_TIME};

option subnet-mask ${DISKLESS_DHCP_NETMASK};
option broadcast-address ${DISKLESS_DHCP_BROADCAST};
option routers ${DISKLESS_DHCP_ROUTER};
option domain-name-servers ${DISKLESS_DHCP_DNS};
option domain-search "${DISKLESS_DHCP_DOMAIN}";
option architecture-type code 93 = unsigned integer 16;

allow booting;
allow bootp;

next-server ${DISKLESS_SERVER_IP};

class "pxeclients" {
    match if substring(option vendor-class-identifier, 0, 9) = "PXEClient";
    next-server ${DISKLESS_SERVER_IP};
    if option architecture-type = 00:07 or option architecture-type = 00:09 {
        filename "uefi/shimx64.efi";
    } else {
        filename "pxelinux.0";
    }
}

subnet ${DISKLESS_DHCP_SUBNET} netmask ${DISKLESS_DHCP_NETMASK} {
    range ${DISKLESS_DHCP_RANGE_FROM} ${DISKLESS_DHCP_RANGE_TO};
}
EOF
}

# Gives one client a fixed address, so it always boots the same installation.
diskless_dhcp_host() {
    DISKLESS_HOST_NAME=${1}
    DISKLESS_HOST_MAC=${2}
    DISKLESS_HOST_IP=${3}
    if [ -z "${DISKLESS_HOST_NAME}" ] || [ -z "${DISKLESS_HOST_MAC}" ] || [ -z "${DISKLESS_HOST_IP}" ]; then
        diskless_error "usage: diskless_dhcp_host HOST_NAME MAC_ADDRESS IP_ADDRESS"
        return 1
    fi
    diskless_write_block "${DISKLESS_DHCP_CONF_FILE}" "host ${DISKLESS_HOST_NAME}" <<EOF
host ${DISKLESS_HOST_NAME} {
    hardware ethernet ${DISKLESS_HOST_MAC};
    fixed-address ${DISKLESS_HOST_IP};
}
EOF
}

##############################################################################
# Boot configuration
##############################################################################

# Writes the boot menu of both firmware types from the installations that
# exist, so the menu can never name an installation that is not there. The
# first installation, or DISKLESS_DEFAULT_NAME, is the default entry.
diskless_tftp_boot_options() {
    sudo mkdir -p "${DISKLESS_TFTP_DIR}"
    diskless_tftp_boot_loaders
    diskless_tftp_boot_menu_bios
    diskless_tftp_boot_menu_uefi
}

# The boot loaders of the server, when the packages that provide them are
# installed. Legacy BIOS boot needs syslinux, which does not exist on every
# release any more, so a missing pxelinux.0 is not an error.
diskless_tftp_boot_loaders() {
    if [ -f "${DISKLESS_SYSLINUX_DIR}/pxelinux.0" ]; then
        for DISKLESS_BOOT_FILE in pxelinux.0 ldlinux.c32 libcom32.c32 libutil.c32 menu.c32; do
            if [ -f "${DISKLESS_SYSLINUX_DIR}/${DISKLESS_BOOT_FILE}" ]; then
                sudo cp -f "${DISKLESS_SYSLINUX_DIR}/${DISKLESS_BOOT_FILE}" "${DISKLESS_TFTP_DIR}/"
            fi
        done
    else
        echo "No ${DISKLESS_SYSLINUX_DIR}/pxelinux.0, BIOS clients are not served"
    fi
    if [ -f "${DISKLESS_EFI_DIR}/shimx64.efi" ]; then
        sudo mkdir -p "${DISKLESS_TFTP_DIR}/uefi"
        for DISKLESS_BOOT_FILE in shimx64.efi grubx64.efi; do
            if [ -f "${DISKLESS_EFI_DIR}/${DISKLESS_BOOT_FILE}" ]; then
                sudo cp -f "${DISKLESS_EFI_DIR}/${DISKLESS_BOOT_FILE}" "${DISKLESS_TFTP_DIR}/uefi/"
            fi
        done
    else
        echo "No ${DISKLESS_EFI_DIR}/shimx64.efi, install shim-x64 and grub2-efi-x64"
    fi
}

# Kernel command line of one installation. The root is mounted over NFS by the
# initramfs, the address comes from the same DHCP server.
diskless_kernel_command_line() {
    diskless_config_load "${1}" || return 1
    echo "root=nfs:${DISKLESS_SERVER_IP}:${DISKLESS_ROOT_DIR}:vers=${DISKLESS_NFS_VERSION} ip=dhcp rw ${DISKLESS_KERNEL_OPTIONS}"
}

diskless_default_name() {
    if [ -n "${DISKLESS_DEFAULT_NAME}" ]; then
        echo "${DISKLESS_DEFAULT_NAME}"
        return 0
    fi
    diskless_names | head -1
}

diskless_tftp_boot_menu_bios() {
    if [ ! -f "${DISKLESS_TFTP_DIR}/pxelinux.0" ]; then
        return 0
    fi
    DISKLESS_MENU_TMP_FILE=$(mktemp)
    {
        echo "# Written by smi-make-diskless(1)."
        echo "DEFAULT menu.c32"
        echo "PROMPT 0"
        echo "TIMEOUT ${DISKLESS_BOOT_TIMEOUT}"
        echo "MENU TITLE setmy.info diskless"
        echo "ONTIMEOUT $(diskless_default_name)"
        for DISKLESS_MENU_NAME in $(diskless_names); do
            echo ""
            echo "LABEL ${DISKLESS_MENU_NAME}"
            echo "    MENU LABEL ${DISKLESS_MENU_NAME}"
            echo "    KERNEL ${DISKLESS_MENU_NAME}/vmlinuz"
            echo "    APPEND initrd=${DISKLESS_MENU_NAME}/initramfs.img $(diskless_kernel_command_line ${DISKLESS_MENU_NAME})"
        done
    } > "${DISKLESS_MENU_TMP_FILE}"
    sudo mkdir -p "${DISKLESS_TFTP_DIR}/pxelinux.cfg"
    sudo cp "${DISKLESS_MENU_TMP_FILE}" "${DISKLESS_TFTP_DIR}/pxelinux.cfg/default"
    rm -f "${DISKLESS_MENU_TMP_FILE}"
}

diskless_tftp_boot_menu_uefi() {
    if [ ! -d "${DISKLESS_TFTP_DIR}/uefi" ]; then
        return 0
    fi
    DISKLESS_MENU_TMP_FILE=$(mktemp)
    {
        echo "# Written by smi-make-diskless(1)."
        echo "set timeout=$(expr ${DISKLESS_BOOT_TIMEOUT} / 10)"
        echo "set default=\"$(diskless_default_name)\""
        for DISKLESS_MENU_NAME in $(diskless_names); do
            echo ""
            echo "menuentry \"${DISKLESS_MENU_NAME}\" --id \"${DISKLESS_MENU_NAME}\" {"
            echo "    linux ${DISKLESS_MENU_NAME}/vmlinuz $(diskless_kernel_command_line ${DISKLESS_MENU_NAME})"
            echo "    initrd ${DISKLESS_MENU_NAME}/initramfs.img"
            echo "}"
        done
    } > "${DISKLESS_MENU_TMP_FILE}"
    sudo cp "${DISKLESS_MENU_TMP_FILE}" "${DISKLESS_TFTP_DIR}/uefi/grub.cfg"
    rm -f "${DISKLESS_MENU_TMP_FILE}"
}

##############################################################################
# Services of the server
##############################################################################

post_diskless_install() {
    sudo systemctl enable --now rpcbind nfs-server
    sudo systemctl enable --now tftp.socket
    sudo systemctl enable --now dhcpd

    sudo firewall-cmd --add-service=dhcp --permanent
    sudo firewall-cmd --add-service=tftp --permanent
    sudo firewall-cmd --add-service=nfs --permanent
    sudo firewall-cmd --add-service=mountd --permanent
    sudo firewall-cmd --add-service=rpc-bind --permanent
    sudo firewall-cmd --reload
}

start_diskless_servers() {
    sudo systemctl restart rpcbind
    sudo systemctl restart nfs-server
    sudo systemctl restart tftp.socket
    sudo systemctl restart dhcpd
}

stop_diskless_servers() {
    sudo systemctl stop dhcpd
    sudo systemctl stop tftp.socket
    sudo systemctl stop nfs-server
}

status_diskless_servers() {
    sudo systemctl --no-pager status rpcbind nfs-server tftp.socket dhcpd
}

##############################################################################
# Management of the installations
##############################################################################

# Names of the installations, one per line.
diskless_names() {
    if [ ! -d "${DISKLESS_DIR}" ]; then
        return 0
    fi
    for DISKLESS_ENTRY in "${DISKLESS_DIR}"/*; do
        if [ -f "${DISKLESS_ENTRY}/diskless.conf" ]; then
            basename "${DISKLESS_ENTRY}"
        fi
    done
}

diskless_list() {
    for DISKLESS_LIST_NAME in $(diskless_names); do
        diskless_config_load "${DISKLESS_LIST_NAME}" || continue
        echo "${DISKLESS_NAME}"
        echo "    server      : ${DISKLESS_SERVER_IP}"
        echo "    release     : ${DISKLESS_RELEASEVER}"
        echo "    kernel      : ${DISKLESS_KERNEL_VERSION}"
        echo "    root        : ${DISKLESS_ROOT_DIR}"
        echo "    boot files  : ${DISKLESS_TFTP_NAME_DIR}"
    done
}

# Installs packages into the chroot of an installation.
diskless_install_package() {
    diskless_config_load "${1}" || return 1
    shift
    if [ ${#} -eq 0 ]; then
        diskless_error "at least one package name is required"
        return 1
    fi
    sudo dnf --releasever="${DISKLESS_RELEASEVER}" \
             --installroot="${DISKLESS_ROOT_DIR}" \
             --disablerepo="*" \
             --enablerepo="${DISKLESS_REPOS}" \
             -y install "${@}"
}

diskless_useradd() {
    diskless_config_load "${1}" || return 1
    DISKLESS_USER_NAME=${2}
    if [ -z "${DISKLESS_USER_NAME}" ]; then
        diskless_error "user name is required"
        return 1
    fi
    diskless_chroot_run useradd "${DISKLESS_USER_NAME}"
}

diskless_passwd() {
    diskless_config_load "${1}" || return 1
    DISKLESS_USER_NAME=${2}
    if [ -z "${DISKLESS_USER_NAME}" ]; then
        diskless_error "user name is required"
        return 1
    fi
    diskless_chroot_run passwd "${DISKLESS_USER_NAME}"
}

# Removes an installation, its exports, its boot files and its boot menu
# entries. The directory of the installation is removed last, so nothing is
# deleted while a chroot mount is still there.
diskless_remove() {
    diskless_config_load "${1}" || return 1
    diskless_chroot_umount
    diskless_remove_block "${DISKLESS_EXPORTS_FILE}" "${DISKLESS_NAME}"
    sudo exportfs -r
    sudo rm -rf "${DISKLESS_TFTP_NAME_DIR}"
    sudo rm -rf "${NAMED_DISKLESS_DIR}"
    diskless_tftp_boot_menu_bios
    diskless_tftp_boot_menu_uefi
}
