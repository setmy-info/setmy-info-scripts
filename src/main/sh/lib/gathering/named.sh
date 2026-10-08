# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
#
# named, the BIND server. The SELinux type of a directory under /var/named decides whether named
# may write into it: named_zone_t is read only, named_cache_t is writable. A zone file in a
# writable directory can be rewritten by a dynamic update or by a compromised named.

section 'named'

packageOf bind
runCommand named -V
serviceState named

topic 'Configuration'
showFile /etc/named.conf
showFilesOf '/etc/named/*.conf'
showFile /etc/named.rfc1912.zones
showTree /etc/named 2
note 'Configuration as named itself reads it:'
runCommand named-checkconf

topic 'Configuration labels and rules'
fileContexts '/etc/named'
expectedContextOf /etc/named.conf /etc/named
expectRestoreconClean /etc/named
expectSelinuxType /etc/named.conf 'named_conf_t etc_t'
expectOwnerMode /etc/named.conf 'root:named' '640'
expectNoGroupOrWorldWrite /etc/named

topic 'Zones'
showTree /var/named 2
runCommand sh -c 'for DIR in /var/named /var/named/data /var/named/dynamic /var/named/slaves; do ls -ldZ ${DIR} 2>/dev/null; done'
fileContexts '/var/named'
expectedContextOf /var/named /var/named/data /var/named/dynamic /var/named/slaves
expectRestoreconClean /var/named

topic 'Zone files'
showFilesOf '/var/named/*.zone'
showFilesOf '/var/named/*.rev'

topic 'Zone checks'
note 'The zone files served from /var/named itself have to be read only for named; the writable'
note 'directories are data, dynamic and slaves, where named keeps journals and transfers:'
expectSelinuxType /var/named 'named_zone_t'
for GATHERING_ZONE in /var/named/*.zone /var/named/*.rev; do
    [ -f "${GATHERING_ZONE}" ] || continue
    expectSelinuxType "${GATHERING_ZONE}" 'named_zone_t'
done
expectSelinuxType /var/named/dynamic 'named_cache_t'
expectSelinuxType /var/named/slaves 'named_cache_t'
expectSelinuxType /var/named/data 'named_cache_t'
expectNoGroupOrWorldWrite /var/named
note 'named_write_master_zones on would let named rewrite the zones it serves:'
expectBoolean named_write_master_zones off

topic 'Keys'
note 'Listed, never printed.'
secretFile /etc/rndc.key
runCommand sh -c 'ls -lZ /etc/named.*key* /var/named/*.key 2>/dev/null || echo "(none)"'

topic 'Process domain'
processContexts 'named'
expectProcessType '/usr/sbin/named' 'named_t'

topic 'Ports and booleans'
runCommand sh -c 'ss -tulpnH | grep -E "named|:53" || echo "(not listening)"'
selinuxPorts 'dns_port_t'
expectPortType 53 'dns_port_t'
selinuxBooleans 'named_'
