# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
#
# Always gathered, whatever profiles were asked for: who and where this machine is, and the
# file system facts that the service profiles build on.

section 'Base'

topic 'Gathering'
runCommand date -u
runCommand id
runCommand sh -c '[ "$(id -u)" -eq 0 ] && echo "running as root, the gathering is complete" || echo "WARNING not running as root, files of mode 600 and 640, the SELinux tools and the nftables ruleset are unreadable, so this gathering is incomplete"'

topic 'Machine'
showFile /etc/os-release
runCommand uname -a
runCommand hostname -f
runCommand uptime

topic 'Network interfaces and addresses'
runCommand ip -brief link show
runCommand ip -brief address show
runCommand ip route show
note 'Interface of the default route, the one the services are reached over:'
runCommand sh -c 'ip -oneline route show default | awk "{ print \$5 }"'
note 'Addresses of that interface:'
runCommand sh -c 'DEV=$(ip -oneline route show default | awk "{ print \$5 }" | head -1); [ -n "${DEV}" ] && ip -brief address show dev "${DEV}" || echo "(no default route)"'

topic 'Listening ports'
note 'Every listening socket with the process behind it. A port here that no profile explains is'
note 'the first thing to look into:'
listeningPorts

topic 'Mounts'
note 'nosuid, nodev and noexec on the data file systems limit what a foothold can do:'
runCommand findmnt -t ext4,xfs,btrfs,tmpfs -o TARGET,SOURCE,FSTYPE,OPTIONS

topic 'Accounts with a login shell'
runCommand sh -c 'getent passwd | awk -F: "\$7 !~ /(nologin|false)$/ { print \$1, \$3, \$6, \$7 }"'
runCommand sh -c 'getent group wheel sudo 2>/dev/null || echo "(none)"'
showFilesOf '/etc/sudoers.d/*'

topic 'Variable data of the toolset'
note 'The directories the toolset itself keeps data in:'
showTree /var/opt/setmy.info 2
showTree /opt/setmy.info/etc 2
