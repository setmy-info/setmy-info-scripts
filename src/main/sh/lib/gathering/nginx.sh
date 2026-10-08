# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
#
# nginx of the web front. It listens on 8080 and 8081 and is reached through the nftables
# redirect, so it needs no privileged port. Content lives under /usr/share/nginx.
#
# What this profile has to answer: can a compromised nginx change its own configuration, write
# into the trees it serves, or read anything outside them. That is decided by the owner and mode
# of those paths, by their SELinux types, and by the httpd_ booleans.

section 'nginx'

packageOf nginx
runCommand nginx -v
serviceState nginx

topic 'Effective configuration'
note 'Every file nginx actually reads, includes expanded:'
runCommand nginx -T

topic 'Configuration files'
showTree /etc/nginx 3
showFilesOf '/etc/nginx/conf.d/vhosts/*.conf'
secretFile /etc/nginx/conf.d/draft-tokens.map

topic 'Configuration labels and rules'
note 'httpd_config_t is read only for the web server: nginx may read its configuration and'
note 'may not write it.'
fileContexts '/etc/nginx'
expectedContextOf /etc/nginx /etc/nginx/nginx.conf /etc/nginx/conf.d/vhosts
expectRestoreconClean /etc/nginx
expectSelinuxType /etc/nginx 'httpd_config_t'
expectOwnerMode /etc/nginx 'root:root' '755'
expectNoGroupOrWorldWrite /etc/nginx

topic 'Certificates and keys'
note 'Private keys are listed, never printed.'
showTree /etc/pki/nginx 1
runCommand sh -c 'ls -lZ /etc/pki/nginx/private 2>/dev/null || echo "(none)"'
runCommand sh -c 'for CERT in /etc/pki/nginx/*.crt /etc/pki/nginx/*.pem; do [ -f "${CERT}" ] && openssl x509 -noout -subject -issuer -dates -ext subjectAltName -in "${CERT}"; done 2>/dev/null || echo "(none)"'
fileContexts '/etc/pki/nginx'
expectRestoreconClean /etc/pki/nginx
expectOwnerMode /etc/pki/nginx/private 'root:nginx' '750'
expectNoGroupOrWorldWrite /etc/pki/nginx

topic 'Served content'
note 'The trees nginx serves, with owner, mode and SELinux type of every path:'
showTree /usr/share/nginx 2
runCommand sh -c 'for TREE in vhosts brands apps errors acme html; do ls -ldZ /usr/share/nginx/${TREE} 2>/dev/null; done'
note 'The policy rules that give these trees their type, the local ones added with'
note 'semanage fcontext -a included:'
fileContexts 'share/nginx'
expectedContextOf /usr/share/nginx/vhosts /usr/share/nginx/brands /usr/share/nginx/apps /usr/share/nginx/errors /usr/share/nginx/acme
expectRestoreconClean /usr/share/nginx

topic 'Content checks'
note 'httpd_sys_content_t is read only for nginx. A writable type, httpd_sys_rw_content_t among'
note 'them, would let a compromised web server change the pages it serves:'
for GATHERING_TREE in /usr/share/nginx/vhosts /usr/share/nginx/brands /usr/share/nginx/apps /usr/share/nginx/errors /usr/share/nginx/acme; do
    expectSelinuxType "${GATHERING_TREE}" 'httpd_sys_content_t'
    expectOwnerMode "${GATHERING_TREE}" 'root:root' '755'
    expectNotWritableType "${GATHERING_TREE}"
    expectNoGroupOrWorldWrite "${GATHERING_TREE}"
done

topic 'Logs'
showTree /var/log/nginx 1
fileContexts '/var/log/nginx'
expectSelinuxType /var/log/nginx 'httpd_log_t'
expectRestoreconClean /var/log/nginx

topic 'Process domain'
processContexts 'nginx'
expectProcessType 'nginx: (master|worker)' 'httpd_t'

topic 'Ports'
runCommand sh -c 'ss -tulpnH | grep -E "nginx|:8080|:8081" || echo "(not listening)"'
selinuxPorts 'http_port_t|vhost_|8080|8081'
expectPortType 8080 'vhost_nginx_port_t http_port_t'
expectPortType 8081 'vhost_nginx_port_t http_port_t'

topic 'Booleans'
note 'Each of these would widen what a compromised web server can reach:'
selinuxBooleans 'httpd_'
expectBoolean httpd_can_network_connect off
expectBoolean httpd_can_network_relay off
expectBoolean httpd_unified off
expectBoolean httpd_enable_homedirs off
expectBoolean httpd_execmem off
expectBoolean httpd_tmp_exec off
expectBoolean httpd_enable_cgi off

topic 'Modules'
selinuxModules 'vhost|httpd'
