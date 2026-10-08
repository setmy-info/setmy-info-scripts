# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
#
# nftables is the only firewall of the web front, firewalld is not used. The ruleset is one file,
# /etc/nftables/main.nft, included from /etc/sysconfig/nftables.conf. The running ruleset is the
# truth; the file is only what will be loaded next time.

section 'nftables'

packageOf nftables
runCommand nft --version
serviceState nftables

topic 'Running ruleset'
note 'What the kernel holds right now:'
runCommand nft list ruleset

topic 'Stored ruleset'
showFile /etc/sysconfig/nftables.conf
showFile /etc/nftables/main.nft
showTree /etc/nftables 2
showTree /etc/systemd/system/nftables.service.d 1

topic 'Configuration labels and modes'
note 'A ruleset a non-root user may write is a firewall a local user can open:'
fileContexts '/etc/nftables|/etc/sysconfig/nftables'
expectRestoreconClean /etc/nftables
expectOwnerMode /etc/nftables/main.nft 'root:root' '600'
expectNoGroupOrWorldWrite /etc/nftables

topic 'Web front redirect'
note 'web_proxy jumps to the chain of the front on duty, to_nginx or to_haproxy:'
runCommand nft list chain inet global_firewall web_proxy
runCommand nft list chain inet global_firewall to_nginx
runCommand nft list chain inet global_firewall to_haproxy

topic 'Sets'
runCommand nft list set inet global_firewall trusted
runCommand nft list set inet global_firewall banned

topic 'Ruleset checks'
runCommand sh -c 'nft list table inet global_firewall > /dev/null 2>&1 && echo "the global_firewall table is loaded" || echo "PROBLEM the global_firewall table is not loaded"'
expectSetting 'nftables service' "$(systemctl is-enabled nftables 2>/dev/null)" 'enabled'
expectSetting 'firewalld' "$(systemctl is-enabled firewalld 2>/dev/null || echo not-installed)" 'masked'
note 'The input chain has to drop by default, so a port that no rule accepts is closed:'
runCommand sh -c 'nft -a list chain inet global_firewall input 2>/dev/null | grep -E "policy|type" || echo "(no input chain)"'
runCommand sh -c 'nft list chain inet global_firewall input 2>/dev/null | grep -q "policy drop" && echo "input policy is drop" || echo "PROBLEM input policy is not drop"'

topic 'Kernel network settings'
showFile /etc/sysctl.d/90-hardening.conf
showFile /etc/modules-load.d/nf_conntrack.conf
runCommand sh -c 'lsmod | grep -E "^nf_conntrack|^nft" || echo "(no netfilter modules listed)"'
note 'The values as they are now, not as the file says:'
expectSysctl net.ipv4.ip_forward 0
expectSysctl net.ipv4.conf.all.rp_filter 1
expectSysctl net.ipv4.tcp_syncookies 1
expectSysctl net.ipv4.conf.all.accept_redirects 0
expectSysctl net.ipv4.conf.all.send_redirects 0
expectSysctl net.ipv4.conf.all.accept_source_route 0
expectSysctl net.ipv4.conf.all.log_martians 1
expectSysctl net.ipv6.conf.all.disable_ipv6 1
expectSysctl net.netfilter.nf_conntrack_tcp_loose 0
