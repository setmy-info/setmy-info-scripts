# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
#
# The SELinux state of the machine as a whole: is it enforcing, what was added locally, which
# modules are loaded, and is every service confined. The per service file labels and process
# domains are in the profile of each service.

section 'SELinux'

topic 'Mode'
runCommand getenforce
runCommand sestatus
showFile /etc/selinux/config
expectSetting 'SELinux mode' "$(getenforce 2>/dev/null)" 'Enforcing'

topic 'Policy and modules'
runCommand semodule -l
note 'Modules of this toolset, built from the sources in lib/selinux/vhost:'
selinuxModules 'vhost'
showTree /opt/setmy.info/lib/selinux 2
showFilesOf '/opt/setmy.info/lib/selinux/vhost/*.te'
note 'A .te source that is not in semodule -l is a module that was written but never loaded:'
runCommand sh -c 'for SOURCE in /opt/setmy.info/lib/selinux/vhost/*.te; do [ -f "${SOURCE}" ] || continue; NAME=$(basename "${SOURCE}" .te); semodule -l 2>/dev/null | grep -qx "${NAME}" && echo "loaded     ${NAME}" || echo "NOT LOADED ${NAME}"; done'
runCommand sh -c 'for SOURCE in /opt/setmy.info/lib/selinux/vhost/*.te; do [ -f "${SOURCE}" ] || continue; NAME=$(basename "${SOURCE}" .te); semodule -l 2>/dev/null | grep -qx "${NAME}" || exit 1; done'

topic 'Local additions'
note 'Everything added to the policy on this machine, which is what an audit has to review:'
note 'file context rules added with semanage fcontext -a:'
localFileContexts
note 'port labels added with semanage port -a:'
runCommand semanage port -l -C
note 'booleans changed from their default:'
runCommand semanage boolean -l -C
note 'users and logins added locally:'
runCommand semanage login -l -C

topic 'Process domains'
note 'Every long running service with its SELinux domain. unconfined_service_t means the policy'
note 'does not confine that process at all, whatever the labels of its files say:'
processContexts 'nginx|haproxy|mosquitto|named|sshd|elixir|beam'
runCommand sh -c 'ps -eo label,args | awk "{ print \$1 }" | cut -d: -f3 | sort | uniq -c | sort -rn | head -20'
runCommand sh -c 'ps -eo label,args | grep -E "unconfined_service_t" | grep -v "grep -E" || echo "(no service runs unconfined)"'

topic 'Denials'
note 'A denial is either an attack that was stopped or a label that is wrong:'
runCommand ausearch -m AVC,USER_AVC -ts today -i
runCommand sh -c 'ausearch -m AVC,USER_AVC -ts recent -i 2>/dev/null | tail -40 || echo "(none)"'
