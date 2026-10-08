# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
#
# Mosquitto, the MQTT broker. Its configuration decides whether anyone may publish without a
# password; its file labels and modes decide whether a compromised broker can reach anything
# beyond its own persistence directory.

section 'MQTT'

packageOf mosquitto
runCommand mosquitto -h
serviceState mosquitto

topic 'Configuration'
showFile /etc/mosquitto/mosquitto.conf
showFilesOf '/etc/mosquitto/conf.d/*.conf'
showFilesOf '/etc/mosquitto/*.acl'
showTree /etc/mosquitto 2

topic 'Configuration labels and rules'
fileContexts '/etc/mosquitto'
expectedContextOf /etc/mosquitto /etc/mosquitto/mosquitto.conf
expectRestoreconClean /etc/mosquitto
expectNoGroupOrWorldWrite /etc/mosquitto

topic 'Credentials and certificates'
note 'Listed, never printed.'
secretFile /etc/mosquitto/passwd
showTree /etc/mosquitto/certs 2
runCommand sh -c 'ls -lZ /etc/mosquitto/certs 2>/dev/null || echo "(none)"'

topic 'Configuration checks'
note 'Read from the configuration files, one setting at a time:'
expectSetting 'allow_anonymous' "$(sh -c 'cat /etc/mosquitto/mosquitto.conf /etc/mosquitto/conf.d/*.conf 2>/dev/null | awk "/^allow_anonymous/ { print \$2 }" | tail -1')" 'false'
expectSetting 'password_file set' "$(sh -c 'cat /etc/mosquitto/mosquitto.conf /etc/mosquitto/conf.d/*.conf 2>/dev/null | awk "/^password_file/ { print \"yes\" }" | tail -1')" 'yes'
note 'Every listener with the address it is bound to. A listener without an address listens on'
note 'every interface:'
runCommand sh -c 'cat /etc/mosquitto/mosquitto.conf /etc/mosquitto/conf.d/*.conf 2>/dev/null | grep -E "^listener|^bind_address|^cafile|^certfile|^keyfile|^require_certificate|^tls_version" || echo "(none)"'
runCommand sh -c 'cat /etc/mosquitto/mosquitto.conf /etc/mosquitto/conf.d/*.conf 2>/dev/null | awk "/^listener/ && NF < 3 { print \"listener without an address: \" \$0 }" || true'
expectOwnerMode /etc/mosquitto/passwd 'root:mosquitto' '640'

topic 'Persistence and logs'
showTree /var/lib/mosquitto 2
showTree /var/log/mosquitto 1
fileContexts '/var/lib/mosquitto'
expectRestoreconClean /var/lib/mosquitto

topic 'Process domain'
processContexts 'mosquitto'
expectProcessType '/usr/sbin/mosquitto' 'mosquitto_t'

topic 'Ports and booleans'
runCommand sh -c 'ss -tulpnH | grep -E "mosquitto|:1883|:8883" || echo "(not listening)"'
selinuxPorts 'mqtt'
expectPortType 8883 'mqtt_port_t vhost_mqtt_port_t'
selinuxBooleans 'mosquitto'
selinuxModules 'mosquitto|mqtt'
