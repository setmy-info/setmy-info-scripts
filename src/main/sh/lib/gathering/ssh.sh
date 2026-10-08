# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
#
# sshd is the one service that is reached directly, without the web front in front of it, so its
# effective configuration, its key modes and its labels are the first thing an audit reads.

section 'SSH'

packageOf openssh-server
runCommand sshd -V
serviceState sshd

topic 'Configuration'
showFile /etc/ssh/sshd_config
showFilesOf '/etc/ssh/sshd_config.d/*.conf'
showTree /etc/ssh 1
note 'Effective configuration, the one that counts, drop-ins and defaults included:'
runCommand sshd -T

topic 'Configuration labels and rules'
fileContexts '/etc/ssh'
expectedContextOf /etc/ssh/sshd_config
expectRestoreconClean /etc/ssh
expectSelinuxType /etc/ssh/sshd_config 'etc_t sshd_config_t'
expectOwnerMode /etc/ssh/sshd_config 'root:root' '600'
expectNoGroupOrWorldWrite /etc/ssh

topic 'Effective configuration checks'
note 'Read from sshd -T, so drop-ins and defaults are included:'
expectSetting 'permitrootlogin' "$(sshd -T 2>/dev/null | awk '/^permitrootlogin/ { print $2 }')" 'no'
expectSetting 'passwordauthentication' "$(sshd -T 2>/dev/null | awk '/^passwordauthentication/ { print $2 }')" 'no'
expectSetting 'permitemptypasswords' "$(sshd -T 2>/dev/null | awk '/^permitemptypasswords/ { print $2 }')" 'no'
expectSetting 'kbdinteractiveauthentication' "$(sshd -T 2>/dev/null | awk '/^kbdinteractiveauthentication/ { print $2 }')" 'no'
expectSetting 'x11forwarding' "$(sshd -T 2>/dev/null | awk '/^x11forwarding/ { print $2 }')" 'no'
expectSetting 'allowtcpforwarding' "$(sshd -T 2>/dev/null | awk '/^allowtcpforwarding/ { print $2 }')" 'no'
expectSetting 'usepam' "$(sshd -T 2>/dev/null | awk '/^usepam/ { print $2 }')" 'yes'
note 'The port sshd listens on, and whether it is the default 22:'
runCommand sh -c 'sshd -T 2>/dev/null | grep -E "^port|^listenaddress|^maxauthtries|^logingracetime|^ciphers|^macs|^kexalgorithms" || echo "(sshd -T needs root)"'

topic 'Host keys'
note 'Private host keys are listed, never printed.'
pathMeta /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ed25519_key
runCommand sh -c 'for KEY in /etc/ssh/ssh_host_*_key.pub; do [ -f "${KEY}" ] && ssh-keygen -l -f "${KEY}"; done 2>/dev/null || echo "(none)"'
runCommand sh -c 'for KEY in /etc/ssh/ssh_host_*_key; do [ -f "${KEY}" ] || continue; MODE=$(stat -c %a "${KEY}"); case ${MODE} in 600|640) echo "ok      ${KEY} ${MODE}" ;; *) echo "PROBLEM ${KEY} ${MODE}" ;; esac; done'

topic 'Authorized keys'
note 'Listed, never printed.'
pathMeta /root/.ssh /root/.ssh/authorized_keys
runCommand sh -c 'ls -ldZ /home/*/.ssh /home/*/.ssh/authorized_keys 2>/dev/null || echo "(none)"'
runCommand sh -c 'for FILE in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do [ -f "${FILE}" ] || continue; echo "${FILE}: $(grep -c . "${FILE}") keys, mode $(stat -c %a "${FILE}"), $(stat -c %U:%G "${FILE}")"; done'

topic 'Process domain'
processContexts 'sshd'
expectProcessType 'sshd: |/usr/sbin/sshd' 'sshd_t'

topic 'Ports and booleans'
runCommand sh -c 'ss -tulpnH | grep -i ssh || echo "(not listening)"'
selinuxPorts 'ssh_port_t'
selinuxBooleans 'ssh_'
expectBoolean ssh_sysadm_login off

topic 'Logins'
runCommand last -n 20
runCommand lastb -n 20
